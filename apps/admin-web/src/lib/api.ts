import { createApiClient } from '@taxcy/api-client';
import { toApiError } from './errors.js';
import { authenticatedFetch, SessionStore } from './session.js';
import { safeLocalStorage } from './storage.js';

export const API_BASE = '/api/v1';

export const sessionStore = new SessionStore(safeLocalStorage, API_BASE);

export const api = createApiClient({
  baseUrl: API_BASE,
  fetch: authenticatedFetch(sessionStore) as typeof fetch,
});

interface FetchResult<T> {
  data?: T;
  error?: unknown;
  response: Response;
}

/**
 * Unwraps an openapi-fetch result: returns the data, or throws an ApiError built from
 * the server's error envelope (so callers can show `error.message`).
 */
export async function call<T>(promise: Promise<FetchResult<T>>): Promise<T> {
  const { data, error, response } = await promise;
  if (error !== undefined || !response.ok) throw toApiError(response.status, error);
  return data as T;
}

/** For 204 responses. */
export async function callVoid(
  promise: Promise<{ error?: unknown; response: Response }>,
): Promise<void> {
  const { error, response } = await promise;
  if (error !== undefined || !response.ok) throw toApiError(response.status, error);
}

/** Header for commands; the server stores the response so a retry can't apply twice. */
export const idempotencyKey = (): { 'Idempotency-Key': string } => ({
  'Idempotency-Key': crypto.randomUUID(),
});
