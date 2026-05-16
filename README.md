# Music Stream Order & Delivery System - Language Comparison

Multi-language implementation comparison for performance testing API.

## Quick Start

Run everything in 3 simple commands:

```bash
# 1. Start the database
docker-compose up -d

# 2. Start the Python API (in the python directory)
cd python
uvicorn app.main:app --port 8080

# 3. Run the acceptance tests (in a new terminal, in the acceptance directory)
cd acceptance
npm test                         # Run all Cucumber tests
```

That's it! The API will be available at `http://localhost:8080/docs`

## First Time Setup

If this is your first time running the project:

```bash
# Install Python dependencies (one-time setup)
cd python
pip install -r requirements.txt

# Install Node dependencies for tests (one-time setup)
cd ../acceptance
npm install
```

## Stopping Services

```bash
# Stop API: Ctrl+C in the terminal
# Stop database: docker-compose down
```

---

## Project Structure

```
lang-compare/
├── python/           # Python FastAPI implementation
├── csharp/          # C# implementation (future)
├── acceptance/      # Cucumber BDD acceptance tests
├── docker-compose.yml
└── README.md
```

## Database Connection

- Host: `localhost:5432`
- Database: `music_stream_dev`
- User: `music_api`
- Password: `music_api_password`
- Connection String: `postgresql://music_api:music_api_password@localhost:5432/music_stream_dev`

## Additional Commands

```bash
# View database logs
docker-compose logs -f postgres

# Run acceptance tests (Cucumber BDD)
cd acceptance
npm test                         # Run all tests
npm run cucumber                 # Run all Cucumber features
npm run cucumber:author          # Run only author management tests
npm run cucumber:multi-tenancy   # Run only multi-tenancy tests
npx cucumber-js features/02-author-management.feature  # Run specific feature

# View test reports
cd acceptance
# HTML report is generated at cucumber-report.html after each run

# Stop and remove all database data
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
