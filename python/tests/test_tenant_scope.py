from collections.abc import AsyncIterator, Callable
from contextlib import asynccontextmanager
from uuid import UUID, uuid4

import pytest
import pytest_asyncio
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app import database
from app.database import Base
from app.models.author import Author
from app.tenant_context import (
    TenantNotSetError,
    current_tenant_id,
    reset_current_tenant,
    set_current_tenant,
)

# ────────────────────────────────────────────────
# Fixtures: fresh in-memory SQLite per test
# ────────────────────────────────────────────────

@pytest_asyncio.fixture
async def session_factory() -> AsyncIterator[async_sessionmaker[AsyncSession]]:
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    factory = async_sessionmaker(engine, expire_on_commit=False)
    yield factory
    await engine.dispose()


@pytest_asyncio.fixture
async def db(session_factory: async_sessionmaker[AsyncSession]) -> AsyncIterator[AsyncSession]:
    async with session_factory() as session:
        yield session


@pytest.fixture
def tenant_a() -> UUID:
    return uuid4()


@pytest.fixture
def tenant_b() -> UUID:
    return uuid4()


@pytest.fixture
def with_tenant() -> Callable[[UUID], object]:
    """Context manager-like helper that sets the tenant for the duration of a `with` block."""

    @asynccontextmanager
    async def _set(tenant_id: UUID) -> AsyncIterator[UUID]:
        token = set_current_tenant(tenant_id)
        try:
            yield tenant_id
        finally:
            reset_current_tenant(token)

    # The fixture returns a plain context-manager factory; tests use `async with`.
    return _set


# ────────────────────────────────────────────────
# tenant_context
# ────────────────────────────────────────────────

class TestTenantContext:
    def test_current_tenant_id_raises_when_unset(self):
        with pytest.raises(TenantNotSetError):
            current_tenant_id()

    def test_set_and_get_round_trips(self, tenant_a):
        token = set_current_tenant(tenant_a)
        try:
            assert current_tenant_id() == tenant_a
        finally:
            reset_current_tenant(token)

    def test_reset_clears_context(self, tenant_a):
        token = set_current_tenant(tenant_a)
        reset_current_tenant(token)
        with pytest.raises(TenantNotSetError):
            current_tenant_id()


# ────────────────────────────────────────────────
# ORM auto-population on INSERT
# ────────────────────────────────────────────────

class TestAutoPopulateTenantId:
    async def test_insert_populates_tenant_id_from_context(self, db, with_tenant, tenant_a):
        async with with_tenant(tenant_a):
            author = Author(name="Hans", country="DE")
            db.add(author)
            await db.commit()
            await db.refresh(author)
        assert author.tenant_id == tenant_a

    async def test_explicit_tenant_id_is_respected(self, db, with_tenant, tenant_a, tenant_b):
        async with with_tenant(tenant_a):
            author = Author(tenant_id=tenant_b, name="Hans", country="DE")
            db.add(author)
            await db.commit()
        assert author.tenant_id == tenant_b

    async def test_insert_without_tenant_context_raises(self, db):
        author = Author(name="Hans", country="DE")
        db.add(author)
        with pytest.raises(TenantNotSetError):
            await db.commit()


# ────────────────────────────────────────────────
# Automatic SELECT/UPDATE/DELETE filtering
# ────────────────────────────────────────────────

class TestAutoFilter:
    async def _seed(self, factory, with_tenant, tenant, name):
        async with factory() as session, with_tenant(tenant):
            author = Author(name=name, country="DE")
            session.add(author)
            await session.commit()
            await session.refresh(author)
            return author.id

    async def test_select_only_sees_current_tenant(
        self, session_factory, with_tenant, tenant_a, tenant_b
    ):
        await self._seed(session_factory, with_tenant, tenant_a, "A-author")
        await self._seed(session_factory, with_tenant, tenant_b, "B-author")

        async with session_factory() as session, with_tenant(tenant_a):
            result = await session.execute(select(Author))
            rows = list(result.scalars().all())
        assert [r.name for r in rows] == ["A-author"]

    async def test_get_by_id_misses_cross_tenant_record(
        self, session_factory, with_tenant, tenant_a, tenant_b
    ):
        a_id = await self._seed(session_factory, with_tenant, tenant_a, "A-author")

        async with session_factory() as session, with_tenant(tenant_b):
            result = await session.execute(select(Author).where(Author.id == a_id))
            assert result.scalar_one_or_none() is None

    async def test_select_without_tenant_context_raises(
        self, session_factory, with_tenant, tenant_a
    ):
        await self._seed(session_factory, with_tenant, tenant_a, "A-author")
        async with session_factory() as session:
            with pytest.raises(TenantNotSetError):
                await session.execute(select(Author))

    async def test_update_does_not_affect_other_tenants(
        self, session_factory, with_tenant, tenant_a, tenant_b
    ):
        a_id = await self._seed(session_factory, with_tenant, tenant_a, "A-author")
        b_id = await self._seed(session_factory, with_tenant, tenant_b, "B-author")

        from sqlalchemy import update as sa_update

        async with session_factory() as session:
            async with with_tenant(tenant_a):
                await session.execute(sa_update(Author).values(name="renamed"))
                await session.commit()

            async with with_tenant(tenant_a):
                result = await session.execute(select(Author).where(Author.id == a_id))
                assert result.scalar_one().name == "renamed"
            async with with_tenant(tenant_b):
                result = await session.execute(select(Author).where(Author.id == b_id))
                assert result.scalar_one().name == "B-author"

    async def test_delete_does_not_affect_other_tenants(
        self, session_factory, with_tenant, tenant_a, tenant_b
    ):
        await self._seed(session_factory, with_tenant, tenant_a, "A-author")
        b_id = await self._seed(session_factory, with_tenant, tenant_b, "B-author")

        from sqlalchemy import delete as sa_delete

        async with session_factory() as session:
            async with with_tenant(tenant_a):
                await session.execute(sa_delete(Author))
                await session.commit()

            async with with_tenant(tenant_b):
                result = await session.execute(select(Author))
                remaining = list(result.scalars().all())
            assert [r.id for r in remaining] == [b_id]


# ────────────────────────────────────────────────
# HTTP middleware
# ────────────────────────────────────────────────

@pytest.fixture
def client(session_factory, monkeypatch):
    """A TestClient wired to an isolated in-memory DB."""
    from app import main

    async def _get_db():
        async with session_factory() as session:
            yield session

    main.app.dependency_overrides[database.get_db] = _get_db
    try:
        with TestClient(main.app) as c:
            yield c
    finally:
        main.app.dependency_overrides.clear()


class TestTenantMiddleware:
    def test_missing_header_on_api_route_returns_400(self, client):
        response = client.get("/api/authors")
        assert response.status_code == 400
        assert response.json() == {
            "error": "VALIDATION_ERROR",
            "message": "X-Tenant-ID header is required",
        }

    def test_invalid_uuid_header_returns_400(self, client):
        response = client.get("/api/authors", headers={"X-Tenant-ID": "not-a-uuid"})
        assert response.status_code == 400
        assert response.json()["error"] == "VALIDATION_ERROR"

    def test_health_check_does_not_require_tenant(self, client):
        response = client.get("/")
        assert response.status_code == 200

    def test_endpoint_does_not_receive_tenant_param(self, client, tenant_a):
        """Authors endpoints take no x_tenant_id argument; create + list should just work."""
        response = client.post(
            "/api/authors",
            headers={"X-Tenant-ID": str(tenant_a)},
            json={"name": "Hans", "country": "DE"},
        )
        assert response.status_code == 201, response.text
        body = response.json()
        assert body["tenant_id"] == str(tenant_a)

        listed = client.get("/api/authors", headers={"X-Tenant-ID": str(tenant_a)})
        assert listed.status_code == 200
        assert listed.json()["total"] == 1

    def test_cross_tenant_get_returns_404(self, client, tenant_a, tenant_b):
        created = client.post(
            "/api/authors",
            headers={"X-Tenant-ID": str(tenant_a)},
            json={"name": "Hans", "country": "DE"},
        ).json()

        response = client.get(
            f"/api/authors/{created['id']}",
            headers={"X-Tenant-ID": str(tenant_b)},
        )
        assert response.status_code == 404
        assert response.json()["error"] == "AUTHOR_NOT_FOUND"

    def test_requests_do_not_leak_tenant_to_each_other(self, client, tenant_a, tenant_b):
        client.post(
            "/api/authors",
            headers={"X-Tenant-ID": str(tenant_a)},
            json={"name": "A", "country": "DE"},
        )
        client.post(
            "/api/authors",
            headers={"X-Tenant-ID": str(tenant_b)},
            json={"name": "B", "country": "DE"},
        )

        a_list = client.get("/api/authors", headers={"X-Tenant-ID": str(tenant_a)}).json()
        b_list = client.get("/api/authors", headers={"X-Tenant-ID": str(tenant_b)}).json()

        assert [a["name"] for a in a_list["authors"]] == ["A"]
        assert [a["name"] for a in b_list["authors"]] == ["B"]
