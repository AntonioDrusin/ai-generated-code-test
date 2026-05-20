from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session
from datetime import datetime, UTC
from uuid import uuid4, UUID
from pydantic import BaseModel, ConfigDict, Field, field_validator
import re

from app.database import get_db, Author as DBAuthor

router = APIRouter(prefix="/api/authors", tags=["Authors"])


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

    model_config = ConfigDict(from_attributes=True)


@router.post(
    "",
    response_model=Author,
    status_code=status.HTTP_201_CREATED,
)
async def create_author(
    author_request: CreateAuthorRequest,
    db: Session = Depends(get_db),
):
    """Create a new author."""
    db_author = DBAuthor(
        id=uuid4(),
        name=author_request.name,
        country=author_request.country,
        created_at=datetime.now(UTC),
    )

    db.add(db_author)
    db.commit()
    db.refresh(db_author)

    return db_author


@router.get("")
async def list_authors(db: Session = Depends(get_db)):
    """List all authors for the tenant."""
    authors = db.query(DBAuthor).all()
    return {
        "authors": authors,
        "total": len(authors),
    }


@router.get("/{author_id}", response_model=Author)
async def get_author(
    author_id: UUID,
    db: Session = Depends(get_db),
):
    """Get author by ID."""
    author = db.query(DBAuthor).filter(DBAuthor.id == author_id).first()

    if not author:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": "AUTHOR_NOT_FOUND", "message": "Author with the given id does not exist"},
        )

    return author
