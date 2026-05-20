from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.author import Author
from app.schemas.author import AuthorResponse, CreateAuthorRequest, ListAuthorsResponse

router = APIRouter(prefix="/api/authors", tags=["Authors"])


@router.post(
    "",
    response_model=AuthorResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_author(
    author_request: CreateAuthorRequest,
    db: AsyncSession = Depends(get_db),
) -> Author:
    """Create a new author."""
    db_author = Author(
        name=author_request.name,
        country=author_request.country,
    )

    db.add(db_author)
    await db.commit()
    await db.refresh(db_author)

    return db_author


@router.get("", response_model=ListAuthorsResponse)
async def list_authors(db: AsyncSession = Depends(get_db)) -> ListAuthorsResponse:
    """List all authors for the tenant."""
    result = await db.execute(select(Author))
    authors = list(result.scalars().all())
    return ListAuthorsResponse(
        authors=[AuthorResponse.model_validate(a) for a in authors],
        total=len(authors),
    )


@router.get("/{author_id}", response_model=AuthorResponse)
async def get_author(
    author_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> Author:
    """Get author by ID."""
    result = await db.execute(select(Author).where(Author.id == author_id))
    author = result.scalar_one_or_none()

    if not author:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "error": "AUTHOR_NOT_FOUND",
                "message": "Author with the given id does not exist",
            },
        )

    return author
