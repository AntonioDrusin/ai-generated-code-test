import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { request } from '@playwright/test';

// World state to share between steps
export class ApiWorld {
  baseURL: string = '';
  tenantId?: string;
  lastResponse?: any;
  lastStatusCode?: number;
  lastError?: any;
  storage: Map<string, any> = new Map();
  apiContext?: any;

  constructor() {
    this.baseURL = typeof process !== 'undefined' && process.env.API_BASE_URL ? process.env.API_BASE_URL : 'http://localhost:8080/api';
    this.storage = new Map();
  }

  async init() {
    this.apiContext = await request.newContext({
      baseURL: this.baseURL,
    });
  }

  async makeRequest(method: string, endpoint: string, options: any = {}) {
    const headers = {
      'Content-Type': 'application/json',
      ...(this.tenantId && { 'X-Tenant-ID': this.tenantId }),
      ...options.headers,
    };

    try {
      const response = await this.apiContext[method.toLowerCase()](endpoint, {
        ...options,
        headers,
      });
      
      this.lastStatusCode = response.status();
      
      if (response.ok()) {
        this.lastResponse = await response.json();
      } else {
        try {
          this.lastError = await response.json();
        } catch {
          this.lastError = { message: await response.text() };
        }
      }
      
      return response;
    } catch (error) {
      this.lastError = error;
      throw error;
    }
  }

  store(key: string, value: any) {
    this.storage.set(key, value);
  }

  retrieve(key: string): any {
    return this.storage.get(key);
  }

  replaceVariables(text: string): string {
    return text.replace(/\{([^}]+)\}/g, (match, key) => {
      const value = this.retrieve(key);
      return value !== undefined ? value : match;
    });
  }

  async cleanup() {
    if (this.apiContext) {
      await this.apiContext.dispose();
    }
  }
}

let world: ApiWorld;

// Initialize world before each scenario
// This replaces the Before hook that was causing issues
async function initializeWorld() {
  world = new ApiWorld();
  await world.init();
}

// Background steps
Given('a tenant with id {string}', async function (tenantId: string) {
  // In a real implementation, you might create the tenant via API
  // For now, we just acknowledge it exists
  world.store('tenant_' + tenantId, tenantId);
});

Given('I use tenant {string}', async function (tenantId: string) {
  world.tenantId = tenantId;
});

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

// Customer steps
When('I create a customer with name {string} and email {string}', async function (name: string, email: string) {
  await world.makeRequest('POST', '/customers', {
    data: { name, email },
  });
});

Then('the customer should be created successfully', async function () {
  expect(world.lastStatusCode).toBe(201);
  expect(world.lastResponse).toHaveProperty('id');
  expect(world.lastResponse).toHaveProperty('name');
  expect(world.lastResponse).toHaveProperty('email');
});

Then('the customer should have name {string}', async function (name: string) {
  expect(world.lastResponse.name).toBe(name);
});

Then('the customer should have email {string}', async function (email: string) {
  expect(world.lastResponse.email).toBe(email);
});

Then('the customer should have status {string}', async function (status: string) {
  expect(world.lastResponse.status).toBe(status);
});

Then('the customer should have balance {float}', async function (balance: number) {
  expect(world.lastResponse.balance).toBe(balance);
});

Then('the customer should have an id', async function () {
  expect(world.lastResponse.id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
});

Then('the customer should have created_at and updated_at timestamps', async function () {
  expect(world.lastResponse.created_at).toBeDefined();
  expect(world.lastResponse.updated_at).toBeDefined();
});

When('I store the customer id as {string}', async function (key: string) {
  world.store(key, world.lastResponse.id);
});

When('I activate customer {string}', async function (customerId: string) {
  const id = world.replaceVariables(customerId);
  await world.makeRequest('POST', `/customers/${id}/activate`);
});

When('I deactivate customer {string}', async function (customerId: string) {
  const id = world.replaceVariables(customerId);
  await world.makeRequest('POST', `/customers/${id}/deactivate`);
});

Then('the customer should be activated successfully', async function () {
  expect(world.lastStatusCode).toBe(200);
});

Then('the customer should be deactivated successfully', async function () {
  expect(world.lastStatusCode).toBe(200);
});

When('I add balance {float} to customer {string}', async function (amount: number, customerId: string) {
  const id = world.replaceVariables(customerId);
  await world.makeRequest('POST', `/customers/${id}/balance`, {
    data: { amount },
  });
});

Then('the balance should be added successfully', async function () {
  expect(world.lastStatusCode).toBe(200);
});

// Error handling steps
Then('the request should fail with status {int}', async function (status: number) {
  expect(world.lastStatusCode).toBe(status);
});

Then('the error should be {string}', async function (errorCode: string) {
  expect(world.lastError.error).toBe(errorCode);
});

Then('the request should fail with status {int} or {int}', async function (status1: number, status2: number) {
  expect([status1, status2]).toContain(world.lastStatusCode);
});

// Placeholder for additional steps - these need to be implemented
// Music Stream steps
// Stream Request steps
// Stream Delivery steps
// Reporting steps
// etc.

export { world, initializeWorld };