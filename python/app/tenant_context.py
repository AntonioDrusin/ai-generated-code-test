from contextvars import ContextVar, Token
from typing import Optional
from uuid import UUID


_current_tenant: ContextVar[Optional[UUID]] = ContextVar("current_tenant", default=None)


class TenantNotSetError(RuntimeError):
    """Raised when a tenant-scoped operation runs without a tenant in context."""


def set_current_tenant(tenant_id: UUID) -> Token:
    return _current_tenant.set(tenant_id)


def reset_current_tenant(token: Token) -> None:
    _current_tenant.reset(token)


def current_tenant_id() -> UUID:
    value = _current_tenant.get()
    if value is None:
        raise TenantNotSetError(
            "No tenant in context. X-Tenant-ID middleware must set it before any DB access."
        )
    return value
