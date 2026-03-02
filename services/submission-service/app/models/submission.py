import uuid
from sqlalchemy import Column, String, Integer, Text, DateTime, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.database import Base


class Submission(Base):
    __tablename__ = "submissions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(String(255), nullable=False)
    problem_id = Column(UUID(as_uuid=True), nullable=False)
    code = Column(Text, nullable=False)
    language = Column(String(50), nullable=False)
    status = Column(String(20), nullable=False, default="pending")
    results = Column(JSONB, nullable=True)
    execution_time = Column(Integer, nullable=True)
    memory_used = Column(Integer, nullable=True)
    competition_id = Column(UUID(as_uuid=True), nullable=True)
    submitted_at = Column(DateTime(timezone=True), server_default=func.now())
