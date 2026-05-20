from uuid import UUID

from fastapi import HTTPException, status


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
