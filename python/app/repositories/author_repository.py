from collections.abc import Sequence
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.author import Author


class AuthorRepository:
    """Data access layer for Author.

    Tenant filtering and tenant_id population are applied transparently by the
    SQLAlchemy event listeners — repository code reads as if single-tenant.
    """

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(self, name: str, country: str) -> Author:
        author = Author(name=name, country=country)
        self.session.add(author)
        await self.session.commit()
        await self.session.refresh(author)
        return author

    async def get_by_id(self, author_id: UUID) -> Author | None:
        result = await self.session.execute(select(Author).where(Author.id == author_id))
        return result.scalar_one_or_none()

    async def list_all(self) -> Sequence[Author]:
        result = await self.session.execute(select(Author))
        return result.scalars().all()
