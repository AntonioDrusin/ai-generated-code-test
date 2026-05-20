from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import TenantEntity


class Author(TenantEntity):
    """Author model for storing author information."""

    __tablename__ = "authors"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    country: Mapped[str] = mapped_column(String(2), nullable=False)

    def __repr__(self) -> str:
        return f"<Author(id={self.id}, name={self.name}, tenant_id={self.tenant_id})>"
