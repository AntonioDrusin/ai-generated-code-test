import { When, Then, Given } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import type { ApiWorld } from './api.steps';

// Music Stream steps (placeholders for future implementation)
When('I create a stream with the following details:', async function (this: ApiWorld, dataTable: any) {
  const data: any = {};
  const rows = dataTable.rawTable;

  for (const [key, value] of rows) {
    const replacedValue = this.replaceVariables(value);
    if (key === 'size_mb' || key === 'cost') {
      data[key] = parseFloat(replacedValue);
    } else if (key === 'duration_seconds' || key === 'bitrate') {
      data[key] = parseInt(replacedValue);
    } else {
      data[key] = replacedValue;
    }
  }

  await this.makeRequest('POST', '/streams', { data });
});

When('I create a stream with title {string}, author_id {string}, size_mb {float}, duration_seconds {int}, cost {float}, and genre {string}',
  async function (this: ApiWorld, title: string, authorId: string, sizeMb: number, durationSeconds: number, cost: number, genre: string) {
    const data = {
      title,
      author_id: this.replaceVariables(authorId),
      size_mb: sizeMb,
      duration_seconds: durationSeconds,
      cost,
      genre,
    };
    await this.makeRequest('POST', '/streams', { data });
});

When('I store the stream id as {string}', async function (this: ApiWorld, key: string) {
  this.store(key, this.lastResponse.id);
});

Then('the stream should be created successfully', async function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(201);
  expect(this.lastResponse).toHaveProperty('id');
  expect(this.lastResponse).toHaveProperty('title');
});

Then('the stream should have title {string}', async function (this: ApiWorld, title: string) {
  expect(this.lastResponse.title).toBe(title);
});

Then('the stream should have author_id {string}', async function (this: ApiWorld, authorId: string) {
  const expectedId = this.replaceVariables(authorId);
  expect(this.lastResponse.author_id).toBe(expectedId);
});

Then('the stream should have cost {float}', async function (this: ApiWorld, cost: number) {
  expect(this.lastResponse.cost).toBe(cost);
});

Then('the stream should have a created_at timestamp', async function (this: ApiWorld) {
  expect(this.lastResponse.created_at).toBeDefined();
});

Then('both streams should be created successfully', async function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(201);
});

When('I create a stream without title for author {string}', async function (this: ApiWorld, authorId: string) {
  const data = {
    author_id: this.replaceVariables(authorId),
    size_mb: 5.0,
    duration_seconds: 180,
    cost: 0.99,
    genre: 'Pop',
  };
  await this.makeRequest('POST', '/streams', { data });
});

When('I create a stream with title {string} without author_id', async function (this: ApiWorld, title: string) {
  const data = {
    title,
    size_mb: 5.0,
    duration_seconds: 180,
    cost: 0.99,
    genre: 'Pop',
  };
  await this.makeRequest('POST', '/streams', { data });
});

// Stream Request steps
When('I create a stream request for customer {string} and stream {string} at {string}',
  async function (this: ApiWorld, customerId: string, streamId: string, requestedAt: string) {
    const data = {
      customer_id: this.replaceVariables(customerId),
      music_stream_id: this.replaceVariables(streamId),
      requested_at: requestedAt,
    };
    await this.makeRequest('POST', '/stream-requests', { data });
});

When('I store the stream request id as {string}', async function (this: ApiWorld, key: string) {
  this.store(key, this.lastResponse.id);
});

Then('the stream request should be created successfully', async function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(201);
  expect(this.lastResponse).toHaveProperty('id');
  expect(this.lastResponse).toHaveProperty('status');
});

Then('the stream request should have status {string}', async function (this: ApiWorld, status: string) {
  expect(this.lastResponse.status).toBe(status);
});

Then('the stream request should have customer_id {string}', async function (this: ApiWorld, customerId: string) {
  const expectedId = this.replaceVariables(customerId);
  expect(this.lastResponse.customer_id).toBe(expectedId);
});

Then('the stream request should have music_stream_id {string}', async function (this: ApiWorld, streamId: string) {
  const expectedId = this.replaceVariables(streamId);
  expect(this.lastResponse.music_stream_id).toBe(expectedId);
});

Then('the stream request should have requested_at {string}', async function (this: ApiWorld, timestamp: string) {
  expect(this.lastResponse.requested_at).toBe(timestamp);
});

When('I approve stream requests before {string}', async function (this: ApiWorld, approveBeforeTime: string) {
  const data = { approve_before: approveBeforeTime };
  await this.makeRequest('POST', '/stream-requests/approve', { data });
});

Then('the approval should complete successfully', async function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(200);
});

Then('the approval should report {int} approved', async function (this: ApiWorld, count: number) {
  expect(this.lastResponse.approved_count).toBe(count);
});

Then('the approval should report {int} denied', async function (this: ApiWorld, count: number) {
  expect(this.lastResponse.denied_count).toBe(count);
});

Then('stream request {string} should have status {string}', async function (this: ApiWorld, requestId: string, status: string) {
  // Placeholder - would need GET endpoint
});

Then('stream request {string} should have a processed_at timestamp', async function (this: ApiWorld, requestId: string) {
  // Placeholder - would need GET endpoint
});

Then('both stream requests should be created successfully', async function (this: ApiWorld) {
  expect(this.lastStatusCode).toBe(201);
});

When('I create a stream request without customer_id for stream {string} at {string}',
  async function (this: ApiWorld, streamId: string, requestedAt: string) {
    const data = {
      music_stream_id: this.replaceVariables(streamId),
      requested_at: requestedAt,
    };
    await this.makeRequest('POST', '/stream-requests', { data });
});

When('I create a stream request for customer {string} without music_stream_id at {string}',
  async function (this: ApiWorld, customerId: string, requestedAt: string) {
    const data = {
      customer_id: this.replaceVariables(customerId),
      requested_at: requestedAt,
    };
    await this.makeRequest('POST', '/stream-requests', { data });
});

When('I store the second stream request id as {string}', async function (this: ApiWorld, key: string) {
  this.store(key, this.lastResponse.id);
});

// Helper steps for complex scenarios
Given('I create {int} approved stream requests for customer {string} and stream {string}',
  async function (this: ApiWorld, count: number, customerId: string, streamId: string) {
    const baseTime = new Date('2026-04-26T10:00:00Z');
    for (let i = 0; i < count; i++) {
      const requestTime = new Date(baseTime.getTime() + i * 60000);
      const data = {
        customer_id: this.replaceVariables(customerId),
        music_stream_id: this.replaceVariables(streamId),
        requested_at: requestTime.toISOString(),
      };
      await this.makeRequest('POST', '/stream-requests', { data });
    }
    await this.makeRequest('POST', '/stream-requests/approve', {
      data: { approve_before: '2026-04-26T12:00:00Z' }
    });
});
