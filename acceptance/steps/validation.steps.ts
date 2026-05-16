import { When, Given } from '@cucumber/cucumber';
import type { ApiWorld } from './api.steps';

// Additional validation/error scenario steps (note: duplicates removed as they're in author.steps.ts)

When('I create a customer with email {string} but no name', async function (this: ApiWorld, email: string) {
  const data = { email };
  await this.makeRequest('POST', '/customers', { data });
});

When('I create a customer with name {string} but no email', async function (this: ApiWorld, name: string) {
  const data = { name };
  await this.makeRequest('POST', '/customers', { data });
});

When('I make a request without a tenant header to create an author', async function (this: ApiWorld) {
  const originalTenantId = this.tenantId;
  this.tenantId = ''; // Remove tenant header

  await this.makeRequest('POST', '/authors', {
    data: { name: 'Test Author', country: 'US' },
  });

  this.tenantId = originalTenantId; // Restore
});

When('I create a stream for author {string} with title {string} and cost {float}',
  async function (this: ApiWorld, authorId: string, title: string, cost: number) {
    const data = {
      title,
      author_id: this.replaceVariables(authorId),
      size_mb: 5.0,
      duration_seconds: 180,
      cost,
      genre: 'Pop',
    };
    await this.makeRequest('POST', '/streams', { data });
});

// Note: "both authors should be created successfully" step is defined in author.steps.ts
