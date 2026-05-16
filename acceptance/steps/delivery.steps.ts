import { When, Then, Given } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import type { ApiWorld } from './api.steps';

// Stream Delivery steps (placeholders for future implementation)
When('I initiate a stream delivery for customer {string} and stream {string}',
  async function (this: ApiWorld, customerId: string, streamId: string) {
    const data = {
      customer_id: this.replaceVariables(customerId),
      music_stream_id: this.replaceVariables(streamId),
    };
    await this.makeRequest('POST', '/stream-deliveries', { data });
});

Then('the stream delivery should be initiated successfully', async function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(201);
  expect(this.lastResponse).toHaveProperty('id');
  expect(this.lastResponse).toHaveProperty('status');
  expect(this.lastResponse).toHaveProperty('stream_url');
});

Then('the stream delivery should have status {string}', async function (this: ApiWorld, status: string) {
  expect(this.lastResponse.status).toBe(status);
});

Then('the stream delivery should have customer_id {string}', async function (this: ApiWorld, customerId: string) {
  const expectedId = this.replaceVariables(customerId);
  expect(this.lastResponse.customer_id).toBe(expectedId);
});

Then('the stream delivery should have music_stream_id {string}', async function (this: ApiWorld, streamId: string) {
  const expectedId = this.replaceVariables(streamId);
  expect(this.lastResponse.music_stream_id).toBe(expectedId);
});

Then('the stream delivery should have a stream_url', async function (this: ApiWorld) {
  expect(this.lastResponse.stream_url).toBeDefined();
  expect(typeof this.lastResponse.stream_url).toBe('string');
});

Then('the stream delivery should have an initiated_at timestamp', async function (this: ApiWorld) {
  expect(this.lastResponse.initiated_at).toBeDefined();
});

Then('the stream delivery should have an expires_at timestamp', async function (this: ApiWorld) {
  expect(this.lastResponse.expires_at).toBeDefined();
});

When('I store the stream delivery id as {string}', async function (this: ApiWorld, key: string) {
  this.store(key, this.lastResponse.id);
});

When('I store the stream url as {string}', async function (this: ApiWorld, key: string) {
  this.store(key, this.lastResponse.stream_url);
});

Then('the customer balance should be {float}', async function (this: ApiWorld, expectedBalance: number) {
  const customerId = this.retrieve('customerId');
  await this.makeRequest('GET', `/customers/${customerId}`);
  expect(this.lastResponse.balance).toBeCloseTo(expectedBalance, 2);
});

Then('the customer {string} balance should be {float}', async function (this: ApiWorld, customerIdKey: string, expectedBalance: number) {
  const customerId = this.replaceVariables(customerIdKey);
  await this.makeRequest('GET', `/customers/${customerId}`);
  expect(this.lastResponse.balance).toBeCloseTo(expectedBalance, 2);
});

Then('the customer {string} balance should remain {float}', async function (this: ApiWorld, customerIdKey: string, expectedBalance: number) {
  const customerId = this.replaceVariables(customerIdKey);
  await this.makeRequest('GET', `/customers/${customerId}`);
  expect(this.lastResponse.balance).toBeCloseTo(expectedBalance, 2);
});

Given('the stream delivery expires at {string}', async function (this: ApiWorld, expiresAt: string) {
  this.store('expiresAt', expiresAt);
});

When('I expire stream deliveries before {string}', async function (this: ApiWorld, expireBefore: string) {
  const data = { expire_before: expireBefore };
  await this.makeRequest('POST', '/stream-deliveries/expire', { data });
});

Then('the expiration should complete successfully', async function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(200);
});

Then('the expiration should report {int} expired', async function (this: ApiWorld, count: number) {
  expect(this.lastResponse.expired_count).toBe(count);
});

Then('stream delivery {string} should have status {string}', async function (this: ApiWorld, deliveryId: string, status: string) {
  // Placeholder - would need GET endpoint
});

Then('stream delivery {string} should have a completed_at timestamp', async function (this: ApiWorld, deliveryId: string) {
  // Placeholder - would need GET endpoint
});

Then('the stream delivery should reference the first approved request', async function (this: ApiWorld) {
  // Placeholder for complex validation
});

Given('all deliveries expire at {string}', async function (this: ApiWorld, expiresAt: string) {
  this.store('allDeliveriesExpireAt', expiresAt);
});

Given('I expire all stream deliveries', async function (this: ApiWorld) {
  const expireTime = this.retrieve('allDeliveriesExpireAt') || '2026-04-26T23:59:59Z';
  await this.makeRequest('POST', '/stream-deliveries/expire', {
    data: { expire_before: expireTime }
  });
});

Given('I expire {int} stream deliveries', async function (this: ApiWorld, count: number) {
  const expireTime = '2026-04-26T23:59:59Z';
  await this.makeRequest('POST', '/stream-deliveries/expire', {
    data: { expire_before: expireTime }
  });
});

Given('I initiate {int} stream deliveries for customer {string} and stream {string}',
  async function (this: ApiWorld, count: number, customerId: string, streamId: string) {
    for (let i = 0; i < count; i++) {
      const data = {
        customer_id: this.replaceVariables(customerId),
        music_stream_id: this.replaceVariables(streamId),
      };
      await this.makeRequest('POST', '/stream-deliveries', { data });
    }
});

Then('the two stream urls should be different', async function (this: ApiWorld) {
  const url1 = this.retrieve('url1');
  const url2 = this.retrieve('url2');
  expect(url1).not.toBe(url2);
});
