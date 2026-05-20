import { client } from "./client/client.gen";

export * from "./client";

export interface ConfigureOptions {
  baseUrl?: string;
  tenantId?: string;
  fetch?: typeof globalThis.fetch;
}

export function configureApiClient({
  baseUrl = "http://localhost:8080/api",
  tenantId,
  fetch,
}: ConfigureOptions = {}) {
  client.setConfig({ baseUrl, fetch });
  if (tenantId) {
    client.interceptors.request.use((request) => {
      request.headers.set("X-Tenant-ID", tenantId);
      return request;
    });
  }
  return client;
}
