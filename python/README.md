# Python API Implementation for Music Stream Order & Delivery System

This directory contains a FastAPI implementation of the Music Stream API for performance testing.

## Prerequisites

- Python 3.10 or higher
- PostgreSQL database (via Docker Compose)

## Setup

### 1. Start PostgreSQL Database

```bash
# From the project root directory
cd ..
docker-compose up -d
```

### 2. Create Virtual Environment

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

## Configuration

Create a `.env` file (optional) to override default settings:

```env
DATABASE_URL=postgresql://music_api:music_api_password@localhost:5432/music_stream_dev
```

Default connection uses the PostgreSQL instance from `docker-compose.yml`.

## Running the API

```bash
# Development mode with auto-reload
uvicorn app.main:app --reload --port 8080

# Production mode
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

## API Documentation

Once running, visit:
- Swagger UI: http://localhost:8080/docs
- ReDoc: http://localhost:8080/redoc

## Database

The application uses PostgreSQL with SQLAlchemy ORM:
- **Connection**: Configured via `DATABASE_URL` environment variable
- **Migrations**: Alembic (for future schema changes)
- **Auto-init**: Tables are created automatically on startup

### Database Schema

Current tables:
- `authors`: Author information with tenant isolation

## Testing

### Unit Tests

Unit tests live in `python/tests/` and use pytest with an in-memory SQLite database — no Postgres or Docker required.

Install the test dependencies once (already included in `requirements.txt` for the app itself):

```bash
pip install pytest httpx
```

Run from the `python/` directory with the venv active:

```bash
pytest tests/
```

### Acceptance Tests

Run Cucumber acceptance tests from the `acceptance` directory:

```bash
cd ../acceptance
npm test                         # Run all tests
npm run cucumber:author          # Run author management tests
```

## Implementation Status

✅ **Completed**
- FastAPI application setup
- PostgreSQL integration with SQLAlchemy
- Author management endpoints (POST, GET, GET by ID)
- Multi-tenant isolation via X-Tenant-ID header
- Request validation and error handling
- All acceptance tests passing

🔄 **Pending**
- Customer management
- Music stream management
- Stream request/delivery workflows
- Payment reporting

