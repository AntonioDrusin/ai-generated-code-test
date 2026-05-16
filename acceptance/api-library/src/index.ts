import createClient from "openapi-fetch";
import type { paths, components } from "./schema";

export type Schemas = components["schemas"];

export interface ClientOptions {
  baseUrl?: string;
  tenantId?: string;
  fetch?: typeof globalThis.fetch;
}

export function createApiClient({
  baseUrl = "http://localhost:8080/api",
  tenantId,
  fetch,
}: ClientOptions = {}) {
  const client = createClient<paths>({ baseUrl, fetch });
  if (tenantId) {
    client.use({
      onRequest({ request }) {
        request.headers.set("X-Tenant-ID", tenantId);
        return request;
      },
    });
  }
  return client;
}

export type { paths, components };
