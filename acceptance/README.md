# Acceptance Tests

Playwright API tests for the Music Stream Order & Delivery System.

## Prerequisites

- Node.js (v20+ recommended)
- Python API server running on `http://localhost:8080`

## Quick Start

```bash
# Install dependencies
npm install

# Start the Python API (in a separate terminal)
cd ../python
python -m uvicorn app.main:app --reload --port 8080

# Run tests (in this directory)
npx playwright test
```

## Running Tests

```bash
# Run all tests
npx playwright test

# Run specific test
npx playwright test tests/02-author-management.spec.ts

# Interactive mode
npx playwright test --ui

# View report
npx playwright show-report
```

## Environment Variables

- `API_BASE_URL`: API base URL (default: `http://localhost:8080`)

## Current Tests

- **02-author-management.spec.ts**: Author creation, validation, multi-tenant isolation

## Writing Tests

```typescript
import { test, expect, request } from '@playwright/test';

test('example', async () => {
  const api = await request.newContext({
    baseURL: 'http://localhost:8080'
  });
  
  const response = await api.post('/api/authors', {
    headers: { 'X-Tenant-ID': 'tenant-uuid' },
    data: { name: 'Test', country: 'US' }
  });
  
  expect(response.status()).toBe(201);
});
```
