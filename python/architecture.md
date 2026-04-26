# Python Architecture Best Practices

## Table of Contents
1. [Type Hints and Typing](#type-hints-and-typing)
2. [Linting and Code Quality](#linting-and-code-quality)
3. [PostgreSQL API Layer Architecture](#postgresql-api-layer-architecture)
4. [Project Structure](#project-structure)

---

## Type Hints and Typing

### Overview
Modern Python (3.10+) provides robust type hinting capabilities that improve code quality, IDE support, and catch errors early.

### Best Practices

#### 1. Use Built-in Generic Types (Python 3.9+)
```python
# ✅ Modern approach (Python 3.9+)
def process_items(items: list[str]) -> dict[str, int]:
    return {item: len(item) for item in items}

# ❌ Old approach (deprecated)
from typing import List, Dict
def process_items(items: List[str]) -> Dict[str, int]:
    return {item: len(item) for item in items}
```

#### 2. Use Union Types with | Operator (Python 3.10+)
```python
# ✅ Modern approach
def get_user(user_id: int | str) -> dict | None:
    pass

# ❌ Old approach
from typing import Union, Optional
def get_user(user_id: Union[int, str]) -> Optional[dict]:
    pass
```

#### 3. Type Aliases for Complex Types
```python
from typing import TypeAlias

UserId: TypeAlias = int | str
UserData: TypeAlias = dict[str, str | int | bool]

def fetch_user(user_id: UserId) -> UserData:
    pass
```

#### 4. Protocol for Structural Typing
```python
from typing import Protocol

class Queryable(Protocol):
    def execute(self, query: str) -> list[dict]:
        ...

def run_query(db: Queryable, query: str) -> list[dict]:
    return db.execute(query)
```

#### 5. Generic Classes
```python
from typing import Generic, TypeVar

T = TypeVar('T')

class Repository(Generic[T]):
    def __init__(self, model: type[T]) -> None:
        self.model = model
    
    def get(self, id: int) -> T | None:
        pass
    
    def all(self) -> list[T]:
        pass
```

#### 6. TypedDict for Structured Dictionaries
```python
from typing import TypedDict, NotRequired

class UserDict(TypedDict):
    id: int
    username: str
    email: str
    age: NotRequired[int]  # Optional field (Python 3.11+)

def create_user(data: UserDict) -> int:
    # IDE will autocomplete and type-check dictionary keys
    return data['id']
```

#### 7. Annotate Return Types and Parameters
```python
# ✅ Always annotate
def calculate_total(prices: list[float], tax_rate: float = 0.1) -> float:
    subtotal = sum(prices)
    return subtotal * (1 + tax_rate)

# ❌ Avoid missing annotations
def calculate_total(prices, tax_rate=0.1):
    subtotal = sum(prices)
    return subtotal * (1 + tax_rate)
```

### Configuration for Type Checking

#### mypy.ini or pyproject.toml
```toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_any_generics = true
disallow_subclassing_any = true
disallow_untyped_calls = true
disallow_incomplete_defs = true
check_untyped_defs = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_ignores = true
warn_no_return = true
```

---

## Linting and Code Quality

### Recommended Tools Stack

#### 1. Ruff - Fast, Modern Linter & Formatter
**Primary recommendation** - replaces Flake8, Black, isort, and more.

```toml
# pyproject.toml
[tool.ruff]
target-version = "py311"
line-length = 100

[tool.ruff.lint]
select = [
    "E",      # pycodstyle errors
    "W",      # pycodstyle warnings
    "F",      # pyflakes
    "I",      # isort
    "N",      # pep8-naming
    "UP",     # pyupgrade
    "B",      # flake8-bugbear
    "C4",     # flake8-comprehensions
    "SIM",    # flake8-simplify
    "TCH",    # flake8-type-checking
    "RUF",    # Ruff-specific rules
]
ignore = [
    "E501",   # Line too long (handled by formatter)
]

[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]  # Unused imports in __init__

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

#### 2. Mypy - Static Type Checker
```bash
# Install
pip install mypy

# Run
mypy src/
```

#### 3. Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.9.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
```

### Code Quality Best Practices

#### 1. Consistent Formatting
```bash
# Format code with Ruff
ruff format .

# Check and fix linting issues
ruff check . --fix
```

#### 2. Docstring Standards (Google Style)
```python
def fetch_user_by_email(email: str, include_deleted: bool = False) -> User | None:
    """Fetch a user by their email address.
    
    Args:
        email: The user's email address
        include_deleted: Whether to include soft-deleted users
    
    Returns:
        User object if found, None otherwise
    
    Raises:
        DatabaseError: If database connection fails
        ValidationError: If email format is invalid
    """
    pass
```

#### 3. Error Handling
```python
class APIError(Exception):
    """Base exception for API errors."""
    pass

class DatabaseError(APIError):
    """Database-related errors."""
    pass

class ValidationError(APIError):
    """Data validation errors."""
    pass

# Use specific exceptions
def get_user(user_id: int) -> User:
    if user_id <= 0:
        raise ValidationError(f"Invalid user_id: {user_id}")
    
    try:
        return db.query(User).filter_by(id=user_id).one()
    except SQLAlchemyError as e:
        raise DatabaseError(f"Failed to fetch user: {e}") from e
```

---

## PostgreSQL API Layer Architecture

### Technology Stack Recommendations

#### Option 1: FastAPI + SQLAlchemy (Recommended)
- **FastAPI**: Modern, fast, async-capable web framework
- **SQLAlchemy 2.0**: Powerful ORM with type hints support
- **Pydantic**: Data validation and serialization
- **asyncpg**: Fast async PostgreSQL driver

#### Option 2: Django + Django ORM
- Full-featured framework with batteries included
- Built-in admin panel and authentication
- Good for traditional applications

### Architecture Layers

```
┌─────────────────────────────────────┐
│         API Layer (FastAPI)         │  ← HTTP Endpoints
├─────────────────────────────────────┤
│      Service Layer (Business)       │  ← Business Logic
├─────────────────────────────────────┤
│    Repository Layer (Data Access)   │  ← Database Operations
├─────────────────────────────────────┤
│       Models (SQLAlchemy ORM)       │  ← Database Schema
├─────────────────────────────────────┤
│          PostgreSQL Database        │  ← Data Storage
└─────────────────────────────────────┘
```

### Implementation Example

#### 1. Database Configuration
```python
# src/database/config.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base

DATABASE_URL = "postgresql+asyncpg://user:password@localhost:5432/dbname"

engine = create_async_engine(
    DATABASE_URL,
    echo=True,  # Log SQL queries in development
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,  # Verify connections before using
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

Base = declarative_base()

async def get_db() -> AsyncSession:
    """Dependency for getting database sessions."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
```

#### 2. Models Layer
```python
# src/models/user.py
from datetime import datetime
from sqlalchemy import String, DateTime, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from src.database.config import Base

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    email: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    
    def __repr__(self) -> str:
        return f"<User(id={self.id}, username={self.username})>"
```

#### 3. Schemas Layer (Pydantic)
```python
# src/schemas/user.py
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field

class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

class UserUpdate(BaseModel):
    username: str | None = None
    email: EmailStr | None = None
    is_active: bool | None = None

class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True  # Enable ORM mode
```

#### 4. Repository Layer
```python
# src/repositories/user_repository.py
from typing import Sequence
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from src.models.user import User

class UserRepository:
    """Data access layer for User operations."""
    
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
    
    async def create(self, username: str, email: str, password_hash: str) -> User:
        """Create a new user."""
        user = User(username=username, email=email, password_hash=password_hash)
        self.session.add(user)
        await self.session.commit()
        await self.session.refresh(user)
        return user
    
    async def get_by_id(self, user_id: int) -> User | None:
        """Get user by ID."""
        result = await self.session.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_email(self, email: str) -> User | None:
        """Get user by email."""
        result = await self.session.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()
    
    async def list_users(
        self, 
        skip: int = 0, 
        limit: int = 100,
        active_only: bool = True
    ) -> Sequence[User]:
        """List users with pagination."""
        query = select(User)
        
        if active_only:
            query = query.where(User.is_active == True)
        
        query = query.offset(skip).limit(limit)
        result = await self.session.execute(query)
        return result.scalars().all()
    
    async def update(self, user: User, **kwargs) -> User:
        """Update user fields."""
        for key, value in kwargs.items():
            if hasattr(user, key) and value is not None:
                setattr(user, key, value)
        
        await self.session.commit()
        await self.session.refresh(user)
        return user
    
    async def delete(self, user: User) -> None:
        """Hard delete a user."""
        await self.session.delete(user)
        await self.session.commit()
    
    async def soft_delete(self, user: User) -> User:
        """Soft delete by setting is_active to False."""
        return await self.update(user, is_active=False)
```

#### 5. Service Layer
```python
# src/services/user_service.py
from src.repositories.user_repository import UserRepository
from src.schemas.user import UserCreate, UserUpdate
from src.models.user import User
from src.exceptions import NotFoundError, ConflictError
from src.security import hash_password

class UserService:
    """Business logic for user operations."""
    
    def __init__(self, repository: UserRepository) -> None:
        self.repository = repository
    
    async def create_user(self, user_data: UserCreate) -> User:
        """Create a new user with validation."""
        # Check if email already exists
        existing_user = await self.repository.get_by_email(user_data.email)
        if existing_user:
            raise ConflictError(f"Email {user_data.email} already registered")
        
        # Hash password
        password_hash = hash_password(user_data.password)
        
        # Create user
        return await self.repository.create(
            username=user_data.username,
            email=user_data.email,
            password_hash=password_hash,
        )
    
    async def get_user(self, user_id: int) -> User:
        """Get user by ID or raise NotFoundError."""
        user = await self.repository.get_by_id(user_id)
        if not user:
            raise NotFoundError(f"User with id {user_id} not found")
        return user
    
    async def update_user(self, user_id: int, user_data: UserUpdate) -> User:
        """Update user information."""
        user = await self.get_user(user_id)
        
        # Check email uniqueness if changing email
        if user_data.email and user_data.email != user.email:
            existing = await self.repository.get_by_email(user_data.email)
            if existing:
                raise ConflictError(f"Email {user_data.email} already in use")
        
        return await self.repository.update(
            user,
            **user_data.model_dump(exclude_unset=True)
        )
```

#### 6. API Layer (FastAPI)
```python
# src/api/routes/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.database.config import get_db
from src.repositories.user_repository import UserRepository
from src.services.user_service import UserService
from src.schemas.user import UserCreate, UserUpdate, UserResponse
from src.exceptions import NotFoundError, ConflictError

router = APIRouter(prefix="/users", tags=["users"])

def get_user_service(db: AsyncSession = Depends(get_db)) -> UserService:
    """Dependency to get user service."""
    repository = UserRepository(db)
    return UserService(repository)

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    service: UserService = Depends(get_user_service),
) -> UserResponse:
    """Create a new user."""
    try:
        user = await service.create_user(user_data)
        return UserResponse.model_validate(user)
    except ConflictError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    service: UserService = Depends(get_user_service),
) -> UserResponse:
    """Get user by ID."""
    try:
        user = await service.get_user(user_id)
        return UserResponse.model_validate(user)
    except NotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_data: UserUpdate,
    service: UserService = Depends(get_user_service),
) -> UserResponse:
    """Update user information."""
    try:
        user = await service.update_user(user_id, user_data)
        return UserResponse.model_validate(user)
    except NotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except ConflictError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))

@router.get("/", response_model=list[UserResponse])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    service: UserService = Depends(get_user_service),
) -> list[UserResponse]:
    """List all users with pagination."""
    repository = service.repository
    users = await repository.list_users(skip=skip, limit=limit)
    return [UserResponse.model_validate(user) for user in users]
```

#### 7. Application Entry Point
```python
# src/main.py
from fastapi import FastAPI
from contextlib import asynccontextmanager

from src.database.config import engine, Base
from src.api.routes import users

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifecycle manager for startup and shutdown."""
    # Startup: Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    yield
    
    # Shutdown: Close connections
    await engine.dispose()

app = FastAPI(
    title="User API",
    description="Example API with PostgreSQL",
    version="1.0.0",
    lifespan=lifespan,
)

# Include routers
app.include_router(users.router, prefix="/api/v1")

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}
```

### Multi-Tenancy

All data in the system is scoped to a tenant. Every table includes a `tenant_id` column, and every API request must include an `X-Tenant-ID` header. All queries and mutations are filtered by tenant.

#### 1. Tenant ID from Request Header
```python
# src/dependencies/tenant.py
from uuid import UUID
from fastapi import Header, HTTPException

async def get_tenant_id(
    x_tenant_id: str = Header(..., alias="X-Tenant-ID")
) -> UUID:
    """Extract and validate tenant ID from request header."""
    try:
        return UUID(x_tenant_id)
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="X-Tenant-ID header must be a valid UUID"
        )

# Usage in route
@router.post("/customers", response_model=CustomerResponse, status_code=201)
async def create_customer(
    request: CreateCustomerRequest,
    tenant_id: UUID = Depends(get_tenant_id),
    db: AsyncSession = Depends(get_db),
) -> CustomerResponse:
    service = CustomerService(CustomerRepository(db))
    return await service.create_customer(tenant_id, request)
```

#### 2. Model Base Class with Tenant ID
```python
# src/models/base.py
import uuid
from datetime import datetime
from sqlalchemy import DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, DeclarativeBase

class Base(DeclarativeBase):
    pass

class TenantEntity(Base):
    """Abstract base for all tenant-scoped entities."""
    __abstract__ = True

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tenant_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

# src/models/customer.py
from sqlalchemy import String, Numeric
from sqlalchemy.orm import Mapped, mapped_column
from src.models.base import TenantEntity

class Customer(TenantEntity):
    __tablename__ = "customers"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="active")
    balance: Mapped[float] = mapped_column(Numeric(12, 2), default=0)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
```

#### 3. Automatic Tenant Filtering with SQLAlchemy Events
```python
# src/database/config.py
from uuid import UUID
from contextvars import ContextVar
from sqlalchemy import event
from sqlalchemy.orm import Session

# Context variable to store current tenant ID
current_tenant_id: ContextVar[UUID | None] = ContextVar("tenant_id", default=None)

def set_tenant_id(tenant_id: UUID) -> None:
    """Set the tenant ID for the current context."""
    current_tenant_id.set(tenant_id)

def get_tenant_id() -> UUID:
    """Get the tenant ID from the current context."""
    tenant_id = current_tenant_id.get()
    if tenant_id is None:
        raise ValueError("Tenant ID not set in context")
    return tenant_id

# Apply automatic tenant filtering on all queries
@event.listens_for(Session, "do_orm_execute")
def receive_do_orm_execute(orm_execute_state):
    """Automatically add tenant_id filter to all ORM queries."""
    if not orm_execute_state.is_select:
        return
    
    # Get tenant from context
    tenant_id = current_tenant_id.get()
    if tenant_id is None:
        return
    
    # Apply filter to all TenantEntity subclasses
    for entity in orm_execute_state.bind_mapper.entities:
        if hasattr(entity, 'tenant_id'):
            orm_execute_state.statement = orm_execute_state.statement.filter(
                entity.tenant_id == tenant_id
            )

# Auto-set tenant_id on insert
@event.listens_for(Session, "before_flush")
def receive_before_flush(session, flush_context, instances):
    """Automatically set tenant_id on new entities."""
    tenant_id = current_tenant_id.get()
    if tenant_id is None:
        return
    
    for instance in session.new:
        if hasattr(instance, 'tenant_id') and instance.tenant_id is None:
            instance.tenant_id = tenant_id

# src/dependencies/tenant.py
from uuid import UUID
from fastapi import Header, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from src.database.config import set_tenant_id, get_db

async def get_tenant_id_from_header(
    x_tenant_id: str = Header(..., alias="X-Tenant-ID")
) -> UUID:
    """Extract and validate tenant ID from request header."""
    try:
        return UUID(x_tenant_id)
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="X-Tenant-ID header must be a valid UUID"
        )

async def get_tenant_scoped_db(
    tenant_id: UUID = Depends(get_tenant_id_from_header),
    db: AsyncSession = Depends(get_db),
) -> AsyncSession:
    """Get database session with tenant context set."""
    set_tenant_id(tenant_id)
    return db
```

#### 4. Repository Layer - Clean Single-Tenant Code
```python
# src/repositories/customer_repository.py
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from src.models.customer import Customer

class CustomerRepository:
    """Repository with automatic tenant scoping - looks like single-tenant code!"""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(self, name: str, email: str) -> Customer:
        # tenant_id is auto-set by event listener
        customer = Customer(name=name, email=email)
        self.session.add(customer)
        await self.session.commit()
        await self.session.refresh(customer)
        return customer

    async def get_by_id(self, customer_id: UUID) -> Customer | None:
        # tenant_id filter is auto-applied by event listener
        result = await self.session.execute(
            select(Customer).where(Customer.id == customer_id)
        )
        return result.scalar_one_or_none()

    async def get_all_active(self) -> list[Customer]:
        # tenant_id filter is auto-applied by event listener
        result = await self.session.execute(
            select(Customer).where(Customer.status == "active")
        )
        return list(result.scalars().all())

    async def update(self, customer: Customer, **kwargs) -> Customer:
        for key, value in kwargs.items():
            if hasattr(customer, key) and value is not None:
                setattr(customer, key, value)
        await self.session.commit()
        await self.session.refresh(customer)
        return customer

# src/api/routes/customers.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from src.dependencies.tenant import get_tenant_scoped_db
from src.repositories.customer_repository import CustomerRepository
from src.schemas.customer import CustomerCreate, CustomerResponse

router = APIRouter(prefix="/customers", tags=["customers"])

@router.post("", response_model=CustomerResponse, status_code=201)
async def create_customer(
    request: CustomerCreate,
    db: AsyncSession = Depends(get_tenant_scoped_db),  # Tenant context is set here
) -> CustomerResponse:
    """Create customer - tenant_id is handled automatically."""
    repository = CustomerRepository(db)
    customer = await repository.create(request.name, request.email)
    return CustomerResponse.model_validate(customer)

@router.get("/{customer_id}", response_model=CustomerResponse)
async def get_customer(
    customer_id: UUID,
    db: AsyncSession = Depends(get_tenant_scoped_db),  # Tenant context is set here
) -> CustomerResponse:
    """Get customer - tenant filtering is automatic."""
    repository = CustomerRepository(db)
    customer = await repository.get_by_id(customer_id)
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    return CustomerResponse.model_validate(customer)
```

#### 5. Indexing for Tenant Queries
```python
# In model definitions, always include tenant_id in composite indexes
from sqlalchemy import Index

class Customer(TenantEntity):
    __tablename__ = "customers"
    # ... fields ...

    __table_args__ = (
        Index("ix_customers_tenant_status", "tenant_id", "status"),
        Index("ix_customers_tenant_email", "tenant_id", "email", unique=True),
    )
```

**Key rules:**
- Every table has a `tenant_id` column (UUID, NOT NULL)
- `X-Tenant-ID` header is required on every API request
- **Automatic filtering**: SQLAlchemy event listeners apply tenant filters transparently
- **Automatic population**: `tenant_id` is auto-set on insert via event listener
- **Context-based**: Tenant ID stored in `ContextVar` for async safety
- All indexes should include `tenant_id` as a leading column
- Cross-tenant access is never permitted
- **Repository code looks like single-tenant code** - no explicit tenant_id parameters needed!

### Database Migrations with Alembic

```bash
# Initialize Alembic
alembic init migrations

# Create migration
alembic revision --autogenerate -m "Create users table"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

### Testing Strategy

```python
# tests/test_user_service.py
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from src.models.user import User
from src.repositories.user_repository import UserRepository
from src.services.user_service import UserService
from src.schemas.user import UserCreate

@pytest.fixture
async def db_session():
    """Create test database session."""
    engine = create_async_engine("postgresql+asyncpg://test:test@localhost:5432/test_db")
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async with async_session() as session:
        yield session
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.mark.asyncio
async def test_create_user(db_session: AsyncSession):
    """Test user creation."""
    repository = UserRepository(db_session)
    service = UserService(repository)
    
    user_data = UserCreate(
        username="testuser",
        email="test@example.com",
        password="securepassword123"
    )
    
    user = await service.create_user(user_data)
    
    assert user.id is not None
    assert user.username == "testuser"
    assert user.email == "test@example.com"
    assert user.is_active is True
```

---

## Project Structure

```
project/
├── src/
│   ├── __init__.py
│   ├── main.py                 # Application entry point
│   ├── config.py               # Configuration management
│   │
│   ├── api/                    # API layer
│   │   ├── __init__.py
│   │   ├── dependencies.py     # Shared dependencies
│   │   └── routes/
│   │       ├── __init__.py
│   │       ├── users.py
│   │       └── auth.py
│   │
│   ├── models/                 # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── base.py
│   │   └── user.py
│   │
│   ├── schemas/                # Pydantic schemas
│   │   ├── __init__.py
│   │   └── user.py
│   │
│   ├── repositories/           # Data access layer
│   │   ├── __init__.py
│   │   ├── base.py
│   │   └── user_repository.py
│   │
│   ├── services/               # Business logic layer
│   │   ├── __init__.py
│   │   └── user_service.py
│   │
│   ├── database/               # Database configuration
│   │   ├── __init__.py
│   │   └── config.py
│   │
│   ├── exceptions.py           # Custom exceptions
│   ├── security.py             # Security utilities
│   └── utils.py                # Helper functions
│
├── tests/                      # Test suite
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_users.py
│   └── test_services.py
│
├── migrations/                 # Alembic migrations
│   └── versions/
│
├── .env.example               # Environment variables template
├ <- .gitignore
├── pyproject.toml             # Project dependencies and config
├── README.md
└── requirements.txt           # Or use pyproject.toml
```

### pyproject.toml Example

```toml
[project]
name = "api-project"
version = "1.0.0"
description = "FastAPI PostgreSQL API"
requires-python = ">=3.11"
dependencies = [
    "fastapi[all]>=0.110.0",
    "sqlalchemy[asyncio]>=2.0.0",
    "asyncpg>=0.29.0",
    "pydantic>=2.6.0",
    "pydantic-settings>=2.2.0",
    "alembic>=1.13.0",
    "python-jose[cryptography]>=3.3.0",
    "passlib[bcrypt]>=1.7.4",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "httpx>=0.27.0",
    "ruff>=0.3.0",
    "mypy>=1.9.0",
    "pre-commit>=3.6.0",
]

[tool.ruff]
target-version = "py311"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "C4", "SIM", "TCH", "RUF"]
ignore = ["E501"]

[tool.mypy]
python_version = "3.11"
strict = true
plugins = ["pydantic.mypy"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

---

## Additional Best Practices

### 1. Connection Pooling
```python
# Use connection pooling for production
engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,           # Number of persistent connections
    max_overflow=10,        # Additional connections under load
    pool_timeout=30,        # Wait time for connection
    pool_recycle=3600,      # Recycle connections after 1 hour
    pool_pre_ping=True,     # Verify connection health
)
```

### 2. Environment Configuration
```python
# src/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    debug: bool = False
    secret_key: str
    
    class Config:
        env_file = ".env"

settings = Settings()
```

### 3. Logging
```python
import logging
from logging.config import dictConfig

logging_config = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "default": {
            "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "default",
        },
    },
    "root": {
        "level": "INFO",
        "handlers": ["console"],
    },
}

dictConfig(logging_config)
```

### 4. Error Handling Middleware
```python
from fastapi import Request, status
from fastapi.responses import JSONResponse

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler."""
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"},
    )
```

---

## Summary

This architecture provides:
- ✅ **Type Safety**: Full type hints with mypy validation
- ✅ **Code Quality**: Automated linting with Ruff
- ✅ **Separation of Concerns**: Clear layered architecture
- ✅ **Testability**: Easy to mock and test each layer
- ✅ **Scalability**: Async support with connection pooling
- ✅ **Maintainability**: Consistent patterns and documentation
- ✅ **Multi-Tenancy**: Tenant isolation via SQLAlchemy event listeners (automatic filtering and population)

For production deployments, also consider:
- Database connection pooling (pgBouncer)
- Caching layer (Redis)
- API rate limiting
- Authentication/Authorization (OAuth2, JWT)
- Monitoring and observability (Prometheus, Grafana)
- CI/CD pipelines
