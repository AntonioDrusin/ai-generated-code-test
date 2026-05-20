from datetime import UTC, datetime
from uuid import UUID, uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import database
from app.database import Base, register_tenant_events
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

@pytest.fixture
def session_factory():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    Factory = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    register_tenant_events(Factory.class_)
    yield Factory
    engine.dispose()


@pytest.fixture
def db(session_factory):
    session = session_factory()
    yield session
    session.close()


@pytest.fixture
def tenant_a():
    return uuid4()


@pytest.fixture
def tenant_b():
    return uuid4()


@pytest.fixture
def with_tenant():
    """Context manager-like helper that sets the tenant for the duration of a `with` block."""
    from contextlib import contextmanager

    @contextmanager
    def _set(tenant_id: UUID):
        token = set_current_tenant(tenant_id)
        try:
            yield tenant_id
        finally:
            reset_current_tenant(token)

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
    def test_insert_populates_tenant_id_from_context(self, db, with_tenant, tenant_a):
        with with_tenant(tenant_a):
            author = Author(id=uuid4(), name="Hans", country="DE", created_at=datetime.now(UTC))
            db.add(author)
            db.commit()
            db.refresh(author)
        assert author.tenant_id == tenant_a

    def test_explicit_tenant_id_is_respected(self, db, with_tenant, tenant_a, tenant_b):
        with with_tenant(tenant_a):
            author = Author(
                id=uuid4(),
                tenant_id=tenant_b,
                name="Hans",
                country="DE",
                created_at=datetime.now(UTC),
            )
            db.add(author)
            db.commit()
        assert author.tenant_id == tenant_b

    def test_insert_without_tenant_context_raises(self, db):
        author = Author(id=uuid4(), name="Hans", country="DE", created_at=datetime.now(UTC))
        db.add(author)
        with pytest.raises(TenantNotSetError):
            db.commit()


# ────────────────────────────────────────────────
# Automatic SELECT/UPDATE/DELETE filtering
# ────────────────────────────────────────────────

class TestAutoFilter:
    def _seed(self, factory, with_tenant, tenant, name):
        session = factory()
        try:
            with with_tenant(tenant):
                author = Author(id=uuid4(), name=name, country="DE", created_at=datetime.now(UTC))
                session.add(author)
                session.commit()
                session.refresh(author)
                return author.id
        finally:
            session.close()

    def test_select_only_sees_current_tenant(self, session_factory, with_tenant, tenant_a, tenant_b):
        self._seed(session_factory, with_tenant, tenant_a, "A-author")
        self._seed(session_factory, with_tenant, tenant_b, "B-author")

        session = session_factory()
        try:
            with with_tenant(tenant_a):
                rows = session.query(Author).all()
            assert [r.name for r in rows] == ["A-author"]
        finally:
            session.close()

    def test_get_by_id_misses_cross_tenant_record(self, session_factory, with_tenant, tenant_a, tenant_b):
        a_id = self._seed(session_factory, with_tenant, tenant_a, "A-author")

        session = session_factory()
        try:
            with with_tenant(tenant_b):
                result = session.query(Author).filter(Author.id == a_id).first()
            assert result is None
        finally:
            session.close()

    def test_select_without_tenant_context_raises(self, session_factory, with_tenant, tenant_a):
        self._seed(session_factory, with_tenant, tenant_a, "A-author")
        session = session_factory()
        try:
            with pytest.raises(TenantNotSetError):
                session.query(Author).all()
        finally:
            session.close()

    def test_update_does_not_affect_other_tenants(self, session_factory, with_tenant, tenant_a, tenant_b):
        a_id = self._seed(session_factory, with_tenant, tenant_a, "A-author")
        b_id = self._seed(session_factory, with_tenant, tenant_b, "B-author")

        session = session_factory()
        try:
            with with_tenant(tenant_a):
                session.query(Author).update({Author.name: "renamed"})
                session.commit()

            with with_tenant(tenant_a):
                assert session.query(Author).filter(Author.id == a_id).one().name == "renamed"
            with with_tenant(tenant_b):
                assert session.query(Author).filter(Author.id == b_id).one().name == "B-author"
        finally:
            session.close()

    def test_delete_does_not_affect_other_tenants(self, session_factory, with_tenant, tenant_a, tenant_b):
        self._seed(session_factory, with_tenant, tenant_a, "A-author")
        b_id = self._seed(session_factory, with_tenant, tenant_b, "B-author")

        session = session_factory()
        try:
            with with_tenant(tenant_a):
                session.query(Author).delete()
                session.commit()

            with with_tenant(tenant_b):
                remaining = session.query(Author).all()
            assert [r.id for r in remaining] == [b_id]
        finally:
            session.close()


# ────────────────────────────────────────────────
# HTTP middleware
# ────────────────────────────────────────────────

@pytest.fixture
def client(session_factory, monkeypatch):
    """A TestClient wired to an isolated in-memory DB."""
    from app import main

    def _get_db():
        session = session_factory()
        try:
            yield session
        finally:
            session.close()

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
