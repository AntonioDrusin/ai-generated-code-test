class APIError(Exception):
    """Base exception for application-level API errors."""

    code: str = "ERROR"

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


class NotFoundError(APIError):
    """Raised when a requested resource does not exist."""

    code = "NOT_FOUND"


class ConflictError(APIError):
    """Raised when a write conflicts with existing state (e.g. unique violations)."""

    code = "CONFLICT"


class ValidationError(APIError):
    """Raised when input fails domain validation (beyond Pydantic-level checks)."""

    code = "VALIDATION_ERROR"


class AuthorNotFoundError(NotFoundError):
    code = "AUTHOR_NOT_FOUND"

    def __init__(self) -> None:
        super().__init__("Author with the given id does not exist")
