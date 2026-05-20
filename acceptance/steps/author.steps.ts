import { When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { randomUUID } from 'crypto';
import type { ApiWorld } from './api.steps';

// Author creation steps
When('I create an author with name {string} and country {string}', async function (this: ApiWorld, name: string, country: string) {
  await this.makeRequest('POST', '/authors', {
    data: { name, country },
  });
});

When('I create an author with country {string} but no name', async function (this: ApiWorld, country: string) {
  await this.makeRequest('POST', '/authors', {
    data: { country },
  });
});

When('I create an author with name {string} but no country', async function (this: ApiWorld, name: string) {
  await this.makeRequest('POST', '/authors', {
    data: { name },
  });
});

// Author validation steps
Then('the author should be created successfully', async function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(201);
  expect(this.lastResponse).toHaveProperty('id');
  expect(this.lastResponse).toHaveProperty('name');
  expect(this.lastResponse).toHaveProperty('country');
  expect(this.lastResponse).toHaveProperty('created_at');
});

Then('both authors should be created successfully', async function (this: ApiWorld) {
  // This step is used after creating multiple authors
  // We check that the last response was successful
  expect(this.lastStatusCode).toBe(201);
  expect(this.lastResponse).toHaveProperty('id');
});

Then('the author should belong to tenant {string}', async function (this: ApiWorld, tenantId: string) {
  expect(this.lastResponse.tenant_id).toBe(tenantId);
});

Then('the author should have name {string}', async function (this: ApiWorld, name: string) {
  expect(this.lastResponse.name).toBe(name);
});

Then('the author should have country {string}', async function (this: ApiWorld, country: string) {
  expect(this.lastResponse.country).toBe(country);
});

Then('the author should have an id', async function (this: ApiWorld) {
  expect(this.lastResponse.id).toBeDefined();
  expect(this.lastResponse.id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
});

Then('the author should have a created_at timestamp', async function (this: ApiWorld) {
  expect(this.lastResponse.created_at).toBeDefined();
  // Verify it's a valid ISO date string
  expect(new Date(this.lastResponse.created_at).toISOString()).toBeTruthy();
});

// Storage steps
When('I store the author id as {string}', async function (this: ApiWorld, key: string) {
  this.store(key, this.lastResponse.id);
});

// Multi-tenancy alias steps (capital T variants used in feature 01)
Then('The author is created successfully', function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(201);
  expect(this.lastResponse).toHaveProperty('id');
  this.store('__last_author_id', this.lastResponse.id);
});

When('I search for that author in a different tenant', async function (this: ApiWorld) {
  const id = this.retrieve('__last_author_id');
  let diffId = this.retrieve('__tenant_diff');
  if (!diffId) {
    diffId = randomUUID();
    this.store('__tenant_diff', diffId);
  }
  this.tenantId = diffId;
  await this.makeRequest('GET', `/authors/${id}`);
});

Then('The author is not found', function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(404);
});

When('I try to retrieve author {string}', async function (this: ApiWorld, authorIdKey: string) {
  const id = this.replaceVariables(authorIdKey);
  await this.makeRequest('GET', `/authors/${id}`);
});
