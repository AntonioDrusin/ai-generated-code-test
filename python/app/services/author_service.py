from collections.abc import Sequence
from uuid import UUID

from app.exceptions import AuthorNotFoundError
from app.models.author import Author
from app.repositories.author_repository import AuthorRepository
from app.schemas.author import CreateAuthorRequest


class AuthorService:
    """Business logic for Author operations."""

    def __init__(self, repository: AuthorRepository) -> None:
        self.repository = repository

    async def create_author(self, request: CreateAuthorRequest) -> Author:
        return await self.repository.create(name=request.name, country=request.country)

    async def get_author(self, author_id: UUID) -> Author:
        author = await self.repository.get_by_id(author_id)
        if author is None:
            raise AuthorNotFoundError
        return author

    async def list_authors(self) -> Sequence[Author]:
        return await self.repository.list_all()
