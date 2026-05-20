from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

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
    db: Session = Depends(get_db),
) -> Author:
    """Create a new author."""
    db_author = Author(
        id=uuid4(),
        name=author_request.name,
        country=author_request.country,
    )

    db.add(db_author)
    db.commit()
    db.refresh(db_author)

    return db_author


@router.get("", response_model=ListAuthorsResponse)
async def list_authors(db: Session = Depends(get_db)) -> ListAuthorsResponse:
    """List all authors for the tenant."""
    authors = db.query(Author).all()
    return ListAuthorsResponse(
        authors=[AuthorResponse.model_validate(a) for a in authors],
        total=len(authors),
    )


@router.get("/{author_id}", response_model=AuthorResponse)
async def get_author(
    author_id: UUID,
    db: Session = Depends(get_db),
) -> Author:
    """Get author by ID."""
    author = db.query(Author).filter(Author.id == author_id).first()

    if not author:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "error": "AUTHOR_NOT_FOUND",
                "message": "Author with the given id does not exist",
            },
        )

    return author
