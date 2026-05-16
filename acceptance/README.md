# Acceptance Tests

Cucumber BDD tests for the Music Stream Order & Delivery System.

## Prerequisites

- Node.js (v20+ recommended)
- Python API server running on `http://localhost:8080`
- PostgreSQL database running (via docker-compose)

## Quick Start

```bash
# Install dependencies
npm install

# Start the database (in project root)
cd ..
docker-compose up -d

# Start the Python API (in a separate terminal)
cd python
uvicorn app.main:app --port 8080

# Run tests (in acceptance directory)
cd ../acceptance
npm test
```

## Running Tests

```bash
# Run all tests
npm test

# Run all Cucumber features
npm run cucumber

# Run specific feature
npm run cucumber:author          # Author management tests
npm run cucumber:multi-tenancy   # Multi-tenancy tests

# Run specific feature file directly
npx cucumber-js features/02-author-management.feature
```

## Environment Variables

- `API_BASE_URL`: API base URL (default: `http://localhost:8080`)

## Test Reports

After running tests, an HTML report is generated at `cucumber-report.html`. Open it in a browser to view detailed test results.

## Current Features

### Implemented
- **02-author-management.feature**: Author creation, validation, multi-tenant isolation (✅ All passing)

### Pending Implementation
- **01-multi-tenancy.feature**: Cross-tenant isolation tests
- **03-customer-management.feature**: Customer lifecycle management
- **04-music-stream-management.feature**: Music stream catalog
- **05-stream-request-workflow.feature**: Stream request approval workflow
- **06-stream-delivery-workflow.feature**: Stream delivery and expiration
- **07-author-payment-reporting.feature**: Payment calculations and reporting
- **08-end-to-end-workflow.feature**: Complete system workflow

## Writing Step Definitions

Step definitions are located in the `steps/` directory:

- **api.steps.ts**: Base API world, HTTP client, error handling
- **author.steps.ts**: Author-specific steps
- **stream.steps.ts**: Music stream and request steps
- **delivery.steps.ts**: Stream delivery steps
- **reporting.steps.ts**: Reporting steps
- **validation.steps.ts**: Additional validation steps

### Example Step Definition

```typescript
import { When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import type { ApiWorld } from './api.steps';

When('I create an author with name {string} and country {string}',
  async function (this: ApiWorld, name: string, country: string) {
    await this.makeRequest('POST', '/api/authors', {
      data: { name, country },
    });
});

Then('the author should be created successfully',
  async function (this: ApiWorld) {
    expect(this.lastStatusCode).toBe(201);
    expect(this.lastResponse).toHaveProperty('id');
});
```

## Project Structure

```
acceptance/
├── features/          # Gherkin feature files
│   ├── 01-multi-tenancy.feature
│   ├── 02-author-management.feature
│   └── ...
├── steps/             # Step definitions
│   ├── api.steps.ts
│   ├── author.steps.ts
│   └── ...
├── cucumber.js        # Cucumber configuration
└── package.json
```
