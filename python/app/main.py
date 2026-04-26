from fastapi import FastAPI, Header, HTTPException, status, Request, Depends
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
from uuid import uuid4, UUID
from pydantic import BaseModel, Field, field_validator
import re

from app.config import get_settings
from app.database import get_db, init_db, Author as DBAuthor

settings = get_settings()

app = FastAPI(
    title=settings.api_title,
    description="API for managing music stream orders and deliveries",
    version=settings.api_version
)


# ────────────────────────────────────────────────
# Startup/Shutdown Events
# ────────────────────────────────────────────────

@app.on_event("startup")
async def startup_event():
    """Initialize database on startup."""
    init_db()


# ────────────────────────────────────────────────
# Request/Response Models
# ────────────────────────────────────────────────

class CreateAuthorRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=255, description="Author's full name")
    country: str = Field(..., min_length=2, max_length=2, description="ISO 3166-1 alpha-2 country code")
    
    @field_validator('country')
    @classmethod
    def validate_country(cls, v: str) -> str:
        if not re.match(r'^[A-Z]{2}$', v):
            raise ValueError('country must be a 2-letter uppercase ISO code')
        return v


class Author(BaseModel):
    id: UUID
    tenant_id: UUID
    name: str
    country: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class ErrorResponse(BaseModel):
    error: str
    message: str


# ────────────────────────────────────────────────
# Helper Functions
# ────────────────────────────────────────────────

def validate_tenant_id(tenant_id: Optional[str]) -> UUID:
    """Validate and parse tenant ID from header."""
    if not tenant_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": "VALIDATION_ERROR", "message": "X-Tenant-ID header is required"}
        )
    
    try:
        return UUID(tenant_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": "VALIDATION_ERROR", "message": "X-Tenant-ID must be a valid UUID"}
        )


# ────────────────────────────────────────────────
# Endpoints
# ────────────────────────────────────────────────

@app.get("/")
async def root():
    """Health check endpoint."""
    return {"status": "ok", "service": "Music Stream API"}


@app.post(
    "/api/authors",
    response_model=Author,
    status_code=status.HTTP_201_CREATED,
    tags=["Authors"]
)
async def create_author(
    author_request: CreateAuthorRequest,
    x_tenant_id: Optional[str] = Header(None, alias="X-Tenant-ID"),
    db: Session = Depends(get_db)
):
    """Create a new author."""
    tenant_id = validate_tenant_id(x_tenant_id)
    
    # Create new author
    db_author = DBAuthor(
        id=uuid4(),
        tenant_id=tenant_id,
        name=author_request.name,
        country=author_request.country,
        created_at=datetime.utcnow()
    )
    
    # Save to database
    db.add(db_author)
    db.commit()
    db.refresh(db_author)
    
    return db_author


@app.get(
    "/api/authors",
    tags=["Authors"]
)
async def list_authors(
    x_tenant_id: Optional[str] = Header(None, alias="X-Tenant-ID"),
    db: Session = Depends(get_db)
):
    """List all authors for the tenant."""
    tenant_id = validate_tenant_id(x_tenant_id)
    
    authors = db.query(DBAuthor).filter(DBAuthor.tenant_id == tenant_id).all()
    
    return {
        "authors": authors,
        "total": len(authors)
    }


@app.get(
    "/api/authors/{author_id}",
    response_model=Author,
    tags=["Authors"]
)
async def get_author(
    author_id: UUID,
    x_tenant_id: Optional[str] = Header(None, alias="X-Tenant-ID"),
    db: Session = Depends(get_db)
):
    """Get author by ID."""
    tenant_id = validate_tenant_id(x_tenant_id)
    
    author = db.query(DBAuthor).filter(
        DBAuthor.id == author_id,
        DBAuthor.tenant_id == tenant_id
    ).first()
    
    if not author:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": "AUTHOR_NOT_FOUND", "message": "Author with the given id does not exist"}
        )
    
    return author


# ────────────────────────────────────────────────
# Error Handlers
# ────────────────────────────────────────────────

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle Pydantic validation errors with custom format."""
    # Extract the first error message
    errors = exc.errors()
    if errors:
        first_error = errors[0]
        field = first_error.get('loc', ['unknown'])[-1]
        message = f"{field} is required" if first_error.get('type') == 'missing' else first_error.get('msg', 'Validation error')
    else:
        message = "Validation error"
    
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"error": "VALIDATION_ERROR", "message": message}
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc: HTTPException):
    """Custom error response format."""
    if isinstance(exc.detail, dict):
        return JSONResponse(
            status_code=exc.status_code,
            content=exc.detail
        )
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": "ERROR", "message": str(exc.detail)}
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
