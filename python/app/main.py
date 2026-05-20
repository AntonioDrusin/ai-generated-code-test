from collections.abc import AsyncIterator, Awaitable, Callable
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request, Response, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.api.routes.authors import router as authors_router
from app.config import get_settings
from app.database import init_db
from app.dependencies.tenant import parse_tenant_header
from app.tenant_context import reset_current_tenant, set_current_tenant

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Initialize database on startup."""
    await init_db()
    yield


app = FastAPI(
    title=settings.api_title,
    description="API for managing music stream orders and deliveries",
    version=settings.api_version,
    lifespan=lifespan,
)


@app.middleware("http")
async def tenant_middleware(
    request: Request,
    call_next: Callable[[Request], Awaitable[Response]],
) -> Response:
    """Read X-Tenant-ID once and stash it in the request-scoped tenant context.

    For /api/* routes the header is required and must parse as a UUID. Other
    routes (e.g. health check) skip the check; if those routes touch the DB
    they will trip the TenantNotSetError safety rail.
    """
    token = None
    if request.url.path.startswith("/api"):
        try:
            tenant_id = parse_tenant_header(request.headers.get("X-Tenant-ID"))
        except HTTPException as exc:
            return JSONResponse(status_code=exc.status_code, content=exc.detail)
        token = set_current_tenant(tenant_id)
    try:
        return await call_next(request)
    finally:
        if token is not None:
            reset_current_tenant(token)


@app.get("/")
async def root() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok", "service": "Music Stream API"}


app.include_router(authors_router)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    """Handle Pydantic validation errors with custom format."""
    errors = exc.errors()
    if errors:
        first_error = errors[0]
        field = first_error.get('loc', ['unknown'])[-1]
        message = f"{field} is required" if first_error.get('type') == 'missing' else first_error.get('msg', 'Validation error')
    else:
        message = "Validation error"

    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"error": "VALIDATION_ERROR", "message": message},
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """Custom error response format."""
    if isinstance(exc.detail, dict):
        return JSONResponse(
            status_code=exc.status_code,
            content=exc.detail,
        )
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": "ERROR", "message": str(exc.detail)},
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
