import uuid
from datetime import UTC, datetime

from sqlalchemy import DateTime, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.database.config import Base


class TenantEntity(Base):
    """Abstract base for all tenant-scoped entities.

    Provides:
      - `id` (UUID primary key)
      - `tenant_id` (UUID, indexed; auto-populated on insert via event listener)
      - `created_at` (UTC timestamp)
    Subclasses are subject to automatic tenant filtering on SELECT/UPDATE/DELETE.
    """

    __abstract__ = True

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    tenant_id: Mapped[uuid.UUID] = mapped_column(Uuid, nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, default=lambda: datetime.now(UTC)
    )


__all__ = ["Base", "TenantEntity"]
