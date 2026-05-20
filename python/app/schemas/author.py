import re
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


class CreateAuthorRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=255, description="Author's full name")
    country: str = Field(
        ..., min_length=2, max_length=2, description="ISO 3166-1 alpha-2 country code"
    )

    @field_validator("country")
    @classmethod
    def validate_country(cls, v: str) -> str:
        if not re.match(r"^[A-Z]{2}$", v):
            raise ValueError("country must be a 2-letter uppercase ISO code")
        return v


class AuthorResponse(BaseModel):
    id: UUID
    tenant_id: UUID
    name: str
    country: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ListAuthorsResponse(BaseModel):
    authors: list[AuthorResponse]
    total: int
