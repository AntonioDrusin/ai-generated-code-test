from sqlalchemy import event
from sqlalchemy.orm import Session, with_loader_criteria
from sqlalchemy.orm.session import ORMExecuteState, SessionTransaction

from app.models.base import TenantEntity
from app.tenant_context import current_tenant_id


def _apply_tenant_filter(execute_state: ORMExecuteState) -> None:
    if execute_state.is_column_load or execute_state.is_relationship_load:
        return
    if not (execute_state.is_select or execute_state.is_update or execute_state.is_delete):
        return
    tenant = current_tenant_id()
    execute_state.statement = execute_state.statement.options(
        with_loader_criteria(
            TenantEntity,
            lambda cls: cls.tenant_id == tenant,
            include_aliases=True,
        )
    )


def _populate_tenant_on_insert(
    session: Session,
    flush_context: SessionTransaction,
    instances: object,
) -> None:
    for obj in session.new:
        if isinstance(obj, TenantEntity) and obj.tenant_id is None:
            obj.tenant_id = current_tenant_id()


def register_tenant_events(session_class: type[Session] = Session) -> None:
    """Wire the tenant-scoping events. Idempotent per session class.

    Events are registered on the synchronous `Session` class. `AsyncSession`
    wraps a `Session` internally, so these listeners fire for async sessions too.
    """
    if not event.contains(session_class, "do_orm_execute", _apply_tenant_filter):
        event.listen(session_class, "do_orm_execute", _apply_tenant_filter)
    if not event.contains(session_class, "before_flush", _populate_tenant_on_insert):
        event.listen(session_class, "before_flush", _populate_tenant_on_insert)
