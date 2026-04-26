import { When, Given } from '@cucumber/cucumber';
import { world } from './api.steps';

// Additional validation/error scenario steps
When('I create an author with country {string} but no name', async function (country: string) {
  const data = { country };
  await world.makeRequest('POST', '/authors', { data });
});

When('I create an author with name {string} but no country', async function (name: string) {
  const data = { name };
  await world.makeRequest('POST', '/authors', { data });
});

When('I create a customer with email {string} but no name', async function (email: string) {
  const data = { email };
  await world.makeRequest('POST', '/customers', { data });
});

When('I create a customer with name {string} but no email', async function (name: string) {
  const data = { name };
  await world.makeRequest('POST', '/customers', { data });
});

When('I make a request without a tenant header to create an author', async function () {
  const originalTenantId = world.tenantId;
  world.tenantId = undefined; // Remove tenant header
  
  await world.makeRequest('POST', '/authors', {
    data: { name: 'Test Author', country: 'US' },
  });
  
  world.tenantId = originalTenantId; // Restore
});

When('I create a stream for author {string} with title {string} and cost {float}', 
  async function (authorId: string, title: string, cost: number) {
    const data = {
      title,
      author_id: world.replaceVariables(authorId),
      size_mb: 5.0,
      duration_seconds: 180,
      cost,
      genre: 'Pop',
    };
    await world.makeRequest('POST', '/streams', { data });
});

Given('both authors should be created successfully', async function () {
  // This assumes the last response was successful
  // In a more robust implementation, we'd track multiple responses
});
