import createClient, { type Middleware } from 'openapi-fetch';
import type { paths } from './schema.js';

export type { components, paths } from './schema.js';

export interface ApiClientOptions {
  /** Base URL including the version prefix, e.g. http://localhost:3000/v1 or /api/v1. */
  baseUrl: string;
  /** Returns the current access token, if signed in. */
  getAccessToken?: () => string | null | undefined;
  fetch?: typeof globalThis.fetch;
}

export function createApiClient(options: ApiClientOptions) {
  const client = createClient<paths>({
    baseUrl: options.baseUrl,
    ...(options.fetch ? { fetch: options.fetch } : {}),
  });
  const auth: Middleware = {
    onRequest({ request }) {
      const token = options.getAccessToken?.();
      if (token) request.headers.set('Authorization', `Bearer ${token}`);
      return request;
    },
  };
  client.use(auth);
  return client;
}

export type ApiClient = ReturnType<typeof createApiClient>;
