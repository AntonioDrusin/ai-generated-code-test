# Music Stream Order & Delivery System - Language Comparison

Multi-language implementation comparison for performance testing API.

## Project Structure

```
lang-compare/
├── python/           # Python FastAPI implementation
├── csharp/          # C# implementation (future)
├── acceptance/      # Playwright acceptance tests
├── docker-compose.yml
└── README.md
```

## Quick Start

### 1. Start PostgreSQL Database

```bash
# Start PostgreSQL in Docker
docker-compose up -d

# Verify it's running
docker-compose ps

# View logs
docker-compose logs -f postgres
```

**Database Connection:**
- Host: `localhost:5432`
- Database: `music_stream_dev`
- User: `music_api`
- Password: `music_api_password`
- Connection String: `postgresql://music_api:music_api_password@localhost:5432/music_stream_dev`

### 2. Run Python API

```bash
cd python

# Create virtual environment (first time only)
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies (first time only)
pip install -r requirements.txt

# Run the API
uvicorn app.main:app --reload --port 8080
```

API will be available at: `http://localhost:8080`
- Swagger UI: `http://localhost:8080/docs`
- ReDoc: `http://localhost:8080/redoc`

### 3. Run Acceptance Tests

```bash
cd acceptance

# Install dependencies (first time only)
npm install

# Run tests
npx playwright test

# Run specific test
npx playwright test tests/02-author-management.spec.ts

# View report
npx playwright show-report
```

## Stopping Services

```bash
# Stop API: Ctrl+C in the terminal

# Stop PostgreSQL
docker-compose down

# Stop and remove all data
docker-compose down -v
```

## API Documentation

See [OpenAPI Specification](openapi.yaml) for complete API documentation.

## Domain Model

See [domain.md](domain.md) for detailed domain model and business rules.

## Development

- **Python Implementation**: See [python/README.md](python/README.md)
- **Acceptance Tests**: See [acceptance/README.md](acceptance/README.md)
- **Docker Setup**: See [DOCKER.md](DOCKER.md)

## Current Implementation Status

✅ **Author Management**
- Create authors with validation
- Multi-tenant isolation
- All acceptance tests passing

🔄 **In Progress**
- Customer management
- Music stream management
- Stream request/delivery workflows
- Payment reporting
