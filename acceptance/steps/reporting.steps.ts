import { When, Then, Given } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { world } from './api.steps';

// Reporting steps
When('I get author payment report', async function () {
  await world.makeRequest('GET', '/reports/author-payments');
});

Then('the report should show {int} author(s)', async function (count: number) {
  expect(world.lastStatusCode).toBe(200);
  expect(world.lastResponse.total_authors).toBe(count);
  expect(world.lastResponse.payments).toHaveLength(count);
});

Then('author {string} should have {int} completed streams', async function (authorIdKey: string, count: number) {
  const authorId = world.replaceVariables(authorIdKey);
  const authorPayment = world.lastResponse.payments.find((p: any) => p.author_id === authorId);
  expect(authorPayment).toBeDefined();
  expect(authorPayment.total_completed_streams).toBe(count);
});

Then('author {string} should have total payment {float}', async function (authorIdKey: string, amount: number) {
  const authorId = world.replaceVariables(authorIdKey);
  const authorPayment = world.lastResponse.payments.find((p: any) => p.author_id === authorId);
  expect(authorPayment).toBeDefined();
  expect(authorPayment.total_payment_amount).toBeCloseTo(amount, 2);
});

Then('the grand total payment should be {float}', async function (amount: number) {
  expect(world.lastResponse.grand_total_amount).toBeCloseTo(amount, 2);
});

Then('the report should only include author {string}', async function (authorIdKey: string) {
  const authorId = world.replaceVariables(authorIdKey);
  expect(world.lastResponse.payments).toHaveLength(1);
  expect(world.lastResponse.payments[0].author_id).toBe(authorId);
});
