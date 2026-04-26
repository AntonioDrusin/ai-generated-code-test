import { test, expect, request, APIRequestContext } from '@playwright/test';
import { randomUUID } from 'crypto';

/**
 * Author Management Tests
 * Implements scenarios from 02-author-management.feature
 */

const BASE_URL = process.env.API_BASE_URL || 'http://localhost:8080';

let apiContext: APIRequestContext;
let tenantId: string;

test.describe('Author Management', () => {
  test.beforeAll(async () => {
    apiContext = await request.newContext({
      baseURL: BASE_URL,
    });
    tenantId = randomUUID();
  });

  test.afterAll(async () => {
    await apiContext.dispose();
  });

  test('Create a new author successfully', async () => {
    const response = await apiContext.post('/api/authors', {
      headers: {
        'X-Tenant-ID': tenantId,
        'Content-Type': 'application/json',
      },
      data: {
        name: 'Hans Zimmer',
        country: 'DE',
      },
    });

    expect(response.status()).toBe(201);
    const author = await response.json();
    
    expect(author).toHaveProperty('id');
    expect(author).toHaveProperty('name', 'Hans Zimmer');
    expect(author).toHaveProperty('country', 'DE');
    expect(author).toHaveProperty('created_at');
    expect(author.id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
  });

  test('Create author with minimum valid data', async () => {
    const response = await apiContext.post('/api/authors', {
      headers: {
        'X-Tenant-ID': tenantId,
        'Content-Type': 'application/json',
      },
      data: {
        name: 'A',
        country: 'US',
      },
    });

    expect(response.status()).toBe(201);
    const author = await response.json();
    expect(author).toHaveProperty('id');
  });

  test('Cannot create author without name', async () => {
    const response = await apiContext.post('/api/authors', {
      headers: {
        'X-Tenant-ID': tenantId,
        'Content-Type': 'application/json',
      },
      data: {
        country: 'DE',
      },
    });

    expect(response.status()).toBe(400);
    const error = await response.json();
    expect(error.error).toBe('VALIDATION_ERROR');
  });

  test('Cannot create author without country', async () => {
    const response = await apiContext.post('/api/authors', {
      headers: {
        'X-Tenant-ID': tenantId,
        'Content-Type': 'application/json',
      },
      data: {
        name: 'Test Author',
      },
    });

    expect(response.status()).toBe(400);
    const error = await response.json();
    expect(error.error).toBe('VALIDATION_ERROR');
  });

  test('Create multiple authors in same tenant', async () => {
    const response1 = await apiContext.post('/api/authors', {
      headers: {
        'X-Tenant-ID': tenantId,
        'Content-Type': 'application/json',
      },
      data: {
        name: 'Author One',
        country: 'US',
      },
    });

    expect(response1.status()).toBe(201);
    const author1 = await response1.json();
    expect(author1).toHaveProperty('id');

    const response2 = await apiContext.post('/api/authors', {
      headers: {
        'X-Tenant-ID': tenantId,
        'Content-Type': 'application/json',
      },
      data: {
        name: 'Author Two',
        country: 'UK',
      },
    });

    expect(response2.status()).toBe(201);
    const author2 = await response2.json();
    expect(author2).toHaveProperty('id');
    expect(author1.id).not.toBe(author2.id);
  });
});
