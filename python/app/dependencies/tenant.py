from collections.abc import AsyncIterator
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.tenant_context import reset_current_tenant, set_current_tenant


def parse_tenant_header(raw: str | None) -> UUID:
    """Validate and parse the X-Tenant-ID header value."""
    if not raw:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": "VALIDATION_ERROR", "message": "X-Tenant-ID header is required"},
        )

    try:
        return UUID(raw)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": "VALIDATION_ERROR", "message": "X-Tenant-ID must be a valid UUID"},
        ) from exc


def get_tenant_id_from_header(x_tenant_id: str | None = Header(default=None)) -> UUID:
    """FastAPI dependency that extracts and validates the X-Tenant-ID header."""
    return parse_tenant_header(x_tenant_id)


async def get_tenant_scoped_db(
    tenant_id: UUID = Depends(get_tenant_id_from_header),
    db: AsyncSession = Depends(get_db),
) -> AsyncIterator[AsyncSession]:
    """Yield a database session with the tenant context set for its lifetime."""
    token = set_current_tenant(tenant_id)
    try:
        yield db
    finally:
        reset_current_tenant(token)
