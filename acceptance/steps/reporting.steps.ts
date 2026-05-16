import { When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import type { ApiWorld } from './api.steps';

// Reporting steps (placeholders for future implementation)
When('I get author payment report', async function (this: ApiWorld) {
  await this.makeRequest('GET', '/reports/author-payments');
});

Then('the report should show {int} author(s)', async function (this: ApiWorld, count: number) {
  expect(this.lastStatusCode).toBe(200);
  expect(this.lastResponse.total_authors).toBe(count);
  expect(this.lastResponse.payments).toHaveLength(count);
});

Then('author {string} should have {int} completed streams', async function (this: ApiWorld, authorIdKey: string, count: number) {
  const authorId = this.replaceVariables(authorIdKey);
  const authorPayment = this.lastResponse.payments.find((p: any) => p.author_id === authorId);
  expect(authorPayment).toBeDefined();
  expect(authorPayment.total_completed_streams).toBe(count);
});

Then('author {string} should have total payment {float}', async function (this: ApiWorld, authorIdKey: string, amount: number) {
  const authorId = this.replaceVariables(authorIdKey);
  const authorPayment = this.lastResponse.payments.find((p: any) => p.author_id === authorId);
  expect(authorPayment).toBeDefined();
  expect(authorPayment.total_payment_amount).toBeCloseTo(amount, 2);
});

Then('the grand total payment should be {float}', async function (this: ApiWorld, amount: number) {
  expect(this.lastResponse.grand_total_amount).toBeCloseTo(amount, 2);
});

Then('the report should only include author {string}', async function (this: ApiWorld, authorIdKey: string) {
  const authorId = this.replaceVariables(authorIdKey);
  expect(this.lastResponse.payments).toHaveLength(1);
  expect(this.lastResponse.payments[0].author_id).toBe(authorId);
});
