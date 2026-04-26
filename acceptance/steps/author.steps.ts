import { When, Then, Given } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { world } from './api.steps';

// Author steps
When('I create an author with name {string} and country {string}', async function (name: string, country: string) {
  await world.makeRequest('POST', '/authors', {
    data: { name, country },
  });
});

Then('the author should be created successfully', async function () {
  expect(world.lastStatusCode).toBe(201);
  expect(world.lastResponse).toHaveProperty('id');
  expect(world.lastResponse).toHaveProperty('name');
  expect(world.lastResponse).toHaveProperty('country');
});

Then('the author should belong to tenant {string}', async function (tenantId: string) {
  expect(world.lastResponse.tenant_id).toBe(tenantId);
});

When('I store the author id as {string}', async function (key: string) {
  world.store(key, world.lastResponse.id);
});

Then('the author should have name {string}', async function (name: string) {
  expect(world.lastResponse.name).toBe(name);
});

Then('the author should have country {string}', async function (country: string) {
  expect(world.lastResponse.country).toBe(country);
});

Then('the author should have an id', async function () {
  expect(world.lastResponse.id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
});

Then('the author should have a created_at timestamp', async function () {
  expect(world.lastResponse.created_at).toBeDefined();
});