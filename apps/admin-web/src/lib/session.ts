import type { Session } from './api-types.js';
import type { KeyValueStore } from './storage.js';

const REFRESH_KEY = 'taxcy.refreshToken';
const DEVICE_KEY = 'taxcy.deviceId';

export type SessionListener = (session: Session | null) => void;

/**
 * Holds the signed-in session. The access token lives only in memory; the refresh
 * token and this browser's device id are persisted. Refreshes are single-flight: any
 * number of concurrent 401s share one /auth/refresh call (refresh tokens rotate, so
 * two parallel refreshes would trip reuse detection and end the session).
 */
export class SessionStore {
  private session: Session | null = null;
  private refreshing: Promise<Session | null> | null = null;
  private readonly listeners = new Set<SessionListener>();

  constructor(
    private readonly storage: KeyValueStore,
    private readonly baseUrl: string,
    private readonly fetchImpl: typeof fetch = (...args) => fetch(...args),
  ) {}

  get current(): Session | null {
    return this.session;
  }

  get accessToken(): string | null {
    return this.session?.accessToken ?? null;
  }

  get refreshToken(): string | null {
    return this.session?.refreshToken ?? this.storage.get(REFRESH_KEY);
  }

  /** Stable per-browser id sent at login (the API records devices). */
  get deviceId(): string {
    const existing = this.storage.get(DEVICE_KEY);
    if (existing) return existing;
    const id = crypto.randomUUID();
    this.storage.set(DEVICE_KEY, id);
    return id;
  }

  subscribe(listener: SessionListener): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  set(session: Session | null): void {
    this.session = session;
    if (session) this.storage.set(REFRESH_KEY, session.refreshToken);
    else this.storage.remove(REFRESH_KEY);
    for (const listener of this.listeners) listener(session);
  }

  /** Exchanges the stored refresh token for a new session; null (and signed out) if that fails. */
  refresh(): Promise<Session | null> {
    this.refreshing ??= this.doRefresh().finally(() => {
      this.refreshing = null;
    });
    return this.refreshing;
  }

  async logout(): Promise<void> {
    const token = this.refreshToken;
    this.set(null);
    if (!token) return;
    try {
      await this.fetchImpl(`${this.baseUrl}/auth/logout`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: token }),
      });
    } catch {
      // Already signed out locally; the token expires on its own.
    }
  }

  private async doRefresh(): Promise<Session | null> {
    const token = this.refreshToken;
    if (!token) return null;
    try {
      const res = await this.fetchImpl(`${this.baseUrl}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: token }),
      });
      if (!res.ok) {
        // A revoked or expired token signs the user out; a 5xx keeps it for a later retry.
        if (res.status < 500) this.set(null);
        return null;
      }
      const session = (await res.json()) as Session;
      this.set(session);
      return session;
    } catch {
      return null;
    }
  }
}

/**
 * fetch for openapi-fetch: adds the bearer token, and on a 401 refreshes once and
 * retries the original request. The request is cloned up front because a body can
 * only be sent once.
 */
export function authenticatedFetch(
  store: SessionStore,
  fetchImpl: typeof fetch = (...a) => fetch(...a),
) {
  return async (input: Request): Promise<Response> => {
    const retry = input.clone();
    const send = (request: Request, token: string | null) => {
      if (token) request.headers.set('Authorization', `Bearer ${token}`);
      return fetchImpl(request);
    };
    const res = await send(input, store.accessToken);
    if (res.status !== 401 || !store.refreshToken) return res;
    const refreshed = await store.refresh();
    if (!refreshed) return res;
    return send(retry, refreshed.accessToken);
  };
}
