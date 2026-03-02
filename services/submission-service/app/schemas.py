from pydantic import BaseModel
from typing import Optional
import uuid


class SubmissionCreate(BaseModel):
    code: str
    language: str
    problem_id: Optional[str] = None


class SubmissionResponse(BaseModel):
    id: str
    status: str
    code: Optional[str] = None
    language: Optional[str] = None
    results: Optional[dict] = None
    execution_time: Optional[int] = None
    memory_used: Optional[int] = None
    submitted_at: Optional[str] = None

    class Config:
        from_attributes = True
