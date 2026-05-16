import { Before, After, Given, When, Then, setWorldConstructor } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { request, APIRequestContext } from '@playwright/test';
import { randomUUID } from 'crypto';

// World class to share state between steps
class ApiWorld {
  baseURL: string;
  tenantId: string;
  lastResponse?: any;
  lastStatusCode?: number;
  lastError?: any;
  storage: Map<string, any>;
  apiContext?: APIRequestContext;

  constructor() {
    this.baseURL = process.env.API_BASE_URL || 'http://localhost:8080';
    this.tenantId = randomUUID();
    this.storage = new Map();
  }

  async init() {
    this.apiContext = await request.newContext({
      baseURL: this.baseURL,
    });
  }

  async makeRequest(method: string, endpoint: string, options: any = {}) {
    if (!this.apiContext) {
      await this.init();
    }

    const headers = {
      'Content-Type': 'application/json',
      'X-Tenant-ID': this.tenantId,
      ...options.headers,
    };

    try {
      const methodLower = method.toLowerCase();
      let response;

      if (methodLower === 'get') {
        response = await this.apiContext!.get(endpoint, { headers });
      } else if (methodLower === 'post') {
        response = await this.apiContext!.post(endpoint, { ...options, headers });
      } else if (methodLower === 'put') {
        response = await this.apiContext!.put(endpoint, { ...options, headers });
      } else if (methodLower === 'patch') {
        response = await this.apiContext!.patch(endpoint, { ...options, headers });
      } else if (methodLower === 'delete') {
        response = await this.apiContext!.delete(endpoint, { headers });
      } else {
        throw new Error(`Unsupported HTTP method: ${method}`);
      }

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

setWorldConstructor(ApiWorld);

// Hooks
Before(async function (this: ApiWorld) {
  await this.init();
});

After(async function (this: ApiWorld) {
  await this.cleanup();
});

// Background steps
Given('a tenant with id {string}', async function (this: ApiWorld, tenantId: string) {
  this.store('tenant_' + tenantId, tenantId);
});

Given('I use tenant {string}', async function (this: ApiWorld, tenantId: string) {
  this.tenantId = tenantId;
});

// Error handling steps
Then('the request should fail with status {int}', async function (this: ApiWorld, status: number) {
  expect(this.lastStatusCode).toBe(status);
});

Then('the error should be {string}', async function (this: ApiWorld, errorCode: string) {
  expect(this.lastError.error).toBe(errorCode);
});

Then('the request should fail with status {int} or {int}', async function (this: ApiWorld, status1: number, status2: number) {
  expect([status1, status2]).toContain(this.lastStatusCode);
});

export { ApiWorld };
