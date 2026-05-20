import { When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { randomUUID } from 'crypto';
import type { ApiWorld } from './api.steps';

// Customer creation
async function createCustomer(world: ApiWorld, name: string, email: string) {
  await world.makeRequest('POST', '/customers', { data: { name, email } });
}

When('I create a customer with name {string} and email {string}', async function (this: ApiWorld, name: string, email: string) {
  await createCustomer(this, name, email);
});

// Customer assertions
Then('the customer should be created successfully', function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(201);
  expect(this.lastResponse).toHaveProperty('id');
});

Then('the customer should have name {string}', function (this: ApiWorld, name: string) {
  expect(this.lastResponse.name).toBe(name);
});

Then('the customer should have email {string}', function (this: ApiWorld, email: string) {
  expect(this.lastResponse.email).toBe(email);
});

Then('the customer should have status {string}', function (this: ApiWorld, status: string) {
  expect(this.lastResponse.status).toBe(status);
});

Then('the customer should have balance {float}', function (this: ApiWorld, balance: number) {
  expect(parseFloat(this.lastResponse.balance)).toBeCloseTo(balance, 2);
});

Then('the customer should have an id', function (this: ApiWorld) {
  expect(this.lastResponse.id).toBeDefined();
  expect(this.lastResponse.id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
});

Then('the customer should have created_at and updated_at timestamps', function (this: ApiWorld) {
  expect(this.lastResponse.created_at).toBeDefined();
  expect(this.lastResponse.updated_at).toBeDefined();
});

When('I store the customer id as {string}', async function (this: ApiWorld, key: string) {
  this.store(key, this.lastResponse.id);
});

// Activate / Deactivate
When('I activate customer {string}', async function (this: ApiWorld, customerIdKey: string) {
  const id = this.replaceVariables(customerIdKey);
  await this.makeRequest('POST', `/customers/${id}/activate`);
});

When('I deactivate customer {string}', async function (this: ApiWorld, customerIdKey: string) {
  const id = this.replaceVariables(customerIdKey);
  await this.makeRequest('POST', `/customers/${id}/deactivate`);
});

Then('the customer should be activated successfully', function (this: ApiWorld) {
  expect([200, 204]).toContain(this.lastStatusCode);
});

Then('the customer should be deactivated successfully', function (this: ApiWorld) {
  expect([200, 204]).toContain(this.lastStatusCode);
});

// Balance
When('I add balance {float} to customer {string}', async function (this: ApiWorld, amount: number, customerIdKey: string) {
  const id = this.replaceVariables(customerIdKey);
  await this.makeRequest('POST', `/customers/${id}/balance`, { data: { amount } });
});

Then('the balance should be added successfully', function (this: ApiWorld) {
  expect([200, 204]).toContain(this.lastStatusCode);
});

// Multi-tenancy alias steps for customers
Then('The customer is created successfully', function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(201);
  expect(this.lastResponse).toHaveProperty('id');
  this.store('__last_customer_id', this.lastResponse.id);
});

When('I search for that customer in a different tenant', async function (this: ApiWorld) {
  const id = this.retrieve('__last_customer_id');
  let diffId = this.retrieve('__tenant_diff');
  if (!diffId) {
    diffId = randomUUID();
    this.store('__tenant_diff', diffId);
  }
  this.tenantId = diffId;
  await this.makeRequest('GET', `/customers/${id}`);
});

Then('The customer is not found', function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(404);
});
