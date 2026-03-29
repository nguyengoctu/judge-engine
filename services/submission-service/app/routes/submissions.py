import logging
import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.submission import Submission
from app.schemas import SubmissionCreate, SubmissionResponse
from app.services.queue import publish_submission
from app.metrics import (
    submissions_total,
    submissions_by_status,
    queue_publish_errors_total,
    submission_create_duration,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/submissions", tags=["Submissions"])


@router.post(
    "",
    response_model=SubmissionResponse,
    status_code=201,
    summary="Submit code",
    description="Submit code for execution. Returns immediately with \
                pending status.",
)
def create_submission(body: SubmissionCreate, db: Session = Depends(get_db)):
    with submission_create_duration.time():
        submission = Submission(
            id=uuid.uuid4(),
            user_id="anonymous",
            problem_id=(
                uuid.UUID(body.problem_id) if body.problem_id else uuid.uuid4()
            ),
            code=body.code,
            language=body.language,
            status="pending",
        )
        db.add(submission)
        db.commit()
        db.refresh(submission)

        # Track submission by language
        submissions_total.labels(language=body.language).inc()
        submissions_by_status.labels(status="pending").inc()

        try:
            publish_submission(str(submission.id), body.code, body.language)
        except Exception as e:
            logger.error(f"Queue publish failed for {submission.id}: {e}")
            submission.status = "error"
            db.commit()
            queue_publish_errors_total.inc()
            submissions_by_status.labels(status="error").inc()

    return SubmissionResponse(
        id=str(submission.id),
        status=submission.status,
    )


@router.get(
    "/{submission_id}",
    response_model=SubmissionResponse,
    summary="Get submission status",
    description="Poll this endpoint to check execution status.",
)
def get_submission(submission_id: str, db: Session = Depends(get_db)):
    try:
        sub_uuid = uuid.UUID(submission_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid submission ID")

    submission = db.query(Submission).filter(Submission.id == sub_uuid).first()
    if not submission:
        raise HTTPException(status_code=404, detail="Submission not found")

    return SubmissionResponse(
        id=str(submission.id),
        status=submission.status,
        code=submission.code,
        language=submission.language,
        results=submission.results,
        execution_time=submission.execution_time,
        memory_used=submission.memory_used,
        submitted_at=(
            submission.submitted_at.isoformat()
            if submission.submitted_at else None
        ),
    )
