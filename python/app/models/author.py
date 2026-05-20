from datetime import UTC, datetime
from uuid import uuid4

from sqlalchemy import Column, DateTime, String, Uuid

from app.models.base import Base, TenantScoped


class Author(TenantScoped, Base):
    """Author model for storing author information."""

    __tablename__ = "authors"

    id = Column(Uuid, primary_key=True, default=uuid4)
    name = Column(String(255), nullable=False)
    country = Column(String(2), nullable=False)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(UTC))

    def __repr__(self) -> str:
        return f"<Author(id={self.id}, name={self.name}, tenant_id={self.tenant_id})>"
