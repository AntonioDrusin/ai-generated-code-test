from sqlalchemy import Column, Uuid

from app.database.config import Base


class TenantScoped:
    """Mixin marking a model as tenant-scoped.

    Models inheriting this get:
      - automatic tenant_id filtering on SELECT/UPDATE/DELETE
      - automatic tenant_id population on INSERT
    Both rely on the request-scoped tenant context. If the context is unset,
    `current_tenant_id()` raises TenantNotSetError — fail closed, never leak.
    """

    tenant_id = Column(Uuid, nullable=False, index=True)


__all__ = ["Base", "TenantScoped"]
