from sqlalchemy import create_engine, Column, String, DateTime, Uuid, event
from sqlalchemy.orm import declarative_base, sessionmaker, Session, with_loader_criteria
from datetime import datetime, UTC
from uuid import uuid4

from app.config import get_settings
from app.tenant_context import current_tenant_id

settings = get_settings()

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    echo=False,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """Dependency to get database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ────────────────────────────────────────────────
# Tenant scoping
# ────────────────────────────────────────────────

class TenantScoped:
    """Mixin marking a model as tenant-scoped.

    Models inheriting this get:
      - automatic tenant_id filtering on SELECT/UPDATE/DELETE
      - automatic tenant_id population on INSERT
    Both rely on the request-scoped tenant context. If the context is unset,
    `current_tenant_id()` raises TenantNotSetError — fail closed, never leak.
    """

    tenant_id = Column(Uuid, nullable=False, index=True)


def _apply_tenant_filter(execute_state):
    if execute_state.is_column_load or execute_state.is_relationship_load:
        return
    if not (execute_state.is_select or execute_state.is_update or execute_state.is_delete):
        return
    tenant = current_tenant_id()
    execute_state.statement = execute_state.statement.options(
        with_loader_criteria(
            TenantScoped,
            lambda cls: cls.tenant_id == tenant,
            include_aliases=True,
        )
    )


def _populate_tenant_on_insert(session, flush_context, instances):
    for obj in session.new:
        if isinstance(obj, TenantScoped) and obj.tenant_id is None:
            obj.tenant_id = current_tenant_id()


def register_tenant_events(session_class=Session) -> None:
    """Wire the tenant-scoping events. Idempotent per session class."""
    if not event.contains(session_class, "do_orm_execute", _apply_tenant_filter):
        event.listen(session_class, "do_orm_execute", _apply_tenant_filter)
    if not event.contains(session_class, "before_flush", _populate_tenant_on_insert):
        event.listen(session_class, "before_flush", _populate_tenant_on_insert)


register_tenant_events()


# ────────────────────────────────────────────────
# Models
# ────────────────────────────────────────────────

class Author(TenantScoped, Base):
    """Author model for storing author information."""

    __tablename__ = "authors"

    id = Column(Uuid, primary_key=True, default=uuid4)
    name = Column(String(255), nullable=False)
    country = Column(String(2), nullable=False)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(UTC))

    def __repr__(self):
        return f"<Author(id={self.id}, name={self.name}, tenant_id={self.tenant_id})>"


def init_db():
    """Initialize database tables."""
    Base.metadata.create_all(bind=engine)
