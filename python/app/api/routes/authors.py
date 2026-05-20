from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies.tenant import get_tenant_scoped_db
from app.models.author import Author
from app.repositories.author_repository import AuthorRepository
from app.schemas.author import AuthorResponse, CreateAuthorRequest, ListAuthorsResponse
from app.services.author_service import AuthorService

router = APIRouter(prefix="/api/authors", tags=["Authors"])


def get_author_service(
    db: AsyncSession = Depends(get_tenant_scoped_db),
) -> AuthorService:
    """Dependency that wires up the Author service with its repository.

    `get_tenant_scoped_db` validates X-Tenant-ID and sets the tenant context for
    the request, so the repository and event listeners can do their work transparently.
    """
    return AuthorService(AuthorRepository(db))


@router.post(
    "",
    response_model=AuthorResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_author(
    author_request: CreateAuthorRequest,
    service: AuthorService = Depends(get_author_service),
) -> Author:
    """Create a new author."""
    return await service.create_author(author_request)


@router.get("", response_model=ListAuthorsResponse)
async def list_authors(
    service: AuthorService = Depends(get_author_service),
) -> ListAuthorsResponse:
    """List all authors for the tenant."""
    authors = await service.list_authors()
    return ListAuthorsResponse(
        authors=[AuthorResponse.model_validate(a) for a in authors],
        total=len(authors),
    )


@router.get("/{author_id}", response_model=AuthorResponse)
async def get_author(
    author_id: UUID,
    service: AuthorService = Depends(get_author_service),
) -> Author:
    """Get author by ID."""
    return await service.get_author(author_id)
