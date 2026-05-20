from fastapi import HTTPException, status
from uuid import UUID


def parse_tenant_header(raw: str | None) -> UUID:
    """Validate and parse the X-Tenant-ID header value."""
    if not raw:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": "VALIDATION_ERROR", "message": "X-Tenant-ID header is required"},
        )

    try:
        return UUID(raw)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": "VALIDATION_ERROR", "message": "X-Tenant-ID must be a valid UUID"},
        )
