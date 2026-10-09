import { describe, expect, it, vi } from 'vitest';
import type { Session } from './api-types.js';
import { authenticatedFetch, SessionStore } from './session.js';
import { memoryStore, safeLocalStorage } from './storage.js';

function session(n: number): Session {
  return {
    accessToken: `access-${String(n)}`,
    accessTokenExpiresAt: '2026-10-09T10:15:00.000Z',
    refreshToken: `refresh-${String(n)}`,
    refreshTokenExpiresAt: '2026-11-08T10:00:00.000Z',
    user: {
      id: '0199c7a2-5b7e-7c3d-9f00-1a2b3c4d5e6f',
      phone: '+919812345678',
      name: 'Anil Sharma',
    },
    activeOrgId: '0199c7a2-5b7e-7c3d-9f00-1a2b3c4d5e70',
    memberships: [],
  };
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

describe('SessionStore', () => {
  it('keeps the access token in memory and persists only the refresh token', () => {
    const storage = memoryStore();
    const store = new SessionStore(storage, '/api/v1', vi.fn());
    store.set(session(1));
    expect(store.accessToken).toBe('access-1');
    expect(storage.get('taxcy.refreshToken')).toBe('refresh-1');
    expect(JSON.stringify(storage)).not.toContain('access-1');
  });

  it('restores from a stored refresh token', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(json(session(2)));
    const store = new SessionStore(
      memoryStore({ 'taxcy.refreshToken': 'refresh-1' }),
      '/api/v1',
      fetchImpl,
    );
    await expect(store.refresh()).resolves.toMatchObject({ accessToken: 'access-2' });
    expect(fetchImpl).toHaveBeenCalledWith(
      '/api/v1/auth/refresh',
      expect.objectContaining({ body: JSON.stringify({ refreshToken: 'refresh-1' }) }),
    );
  });

  it('shares one refresh between concurrent callers (rotating tokens can only be used once)', async () => {
    let resolve: (r: Response) => void = () => undefined;
    const fetchImpl = vi.fn().mockReturnValue(
      new Promise<Response>((r) => {
        resolve = r;
      }),
    );
    const store = new SessionStore(
      memoryStore({ 'taxcy.refreshToken': 'refresh-1' }),
      '/api/v1',
      fetchImpl,
    );
    const a = store.refresh();
    const b = store.refresh();
    resolve(json(session(2)));
    await expect(Promise.all([a, b])).resolves.toEqual([session(2), session(2)]);
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it('signs out when the refresh token is rejected, but keeps it through a server error', async () => {
    const storage = memoryStore({ 'taxcy.refreshToken': 'refresh-1' });
    const listener = vi.fn();
    const flaky = new SessionStore(storage, '/api/v1', vi.fn().mockResolvedValue(json({}, 503)));
    await expect(flaky.refresh()).resolves.toBeNull();
    expect(storage.get('taxcy.refreshToken')).toBe('refresh-1');

    const store = new SessionStore(
      storage,
      '/api/v1',
      vi
        .fn()
        .mockResolvedValue(json({ error: { code: 'UNAUTHENTICATED', message: 'revoked' } }, 401)),
    );
    store.subscribe(listener);
    await expect(store.refresh()).resolves.toBeNull();
    expect(storage.get('taxcy.refreshToken')).toBeNull();
    expect(listener).toHaveBeenCalledWith(null);
  });

  it('logout forgets the session and revokes it on the server', async () => {
    const storage = memoryStore();
    const fetchImpl = vi.fn().mockResolvedValue(new Response(null, { status: 204 }));
    const store = new SessionStore(storage, '/api/v1', fetchImpl);
    store.set(session(1));
    await store.logout();
    expect(store.current).toBeNull();
    expect(storage.get('taxcy.refreshToken')).toBeNull();
    expect(fetchImpl).toHaveBeenCalledWith(
      '/api/v1/auth/logout',
      expect.objectContaining({ method: 'POST' }),
    );
  });

  it('creates a device id once and reuses it', () => {
    const store = new SessionStore(memoryStore(), '/api/v1', vi.fn());
    const id = store.deviceId;
    expect(id).toMatch(/^[0-9a-f-]{36}$/);
    expect(store.deviceId).toBe(id);
  });
});

describe('authenticatedFetch', () => {
  it('adds the bearer token', async () => {
    const store = new SessionStore(memoryStore(), '/api/v1', vi.fn());
    store.set(session(1));
    const fetchImpl = vi.fn().mockResolvedValue(json({ ok: true }));
    await authenticatedFetch(store, fetchImpl)(new Request('http://x/api/v1/vehicles'));
    const sent = fetchImpl.mock.calls[0]?.[0] as Request;
    expect(sent.headers.get('Authorization')).toBe('Bearer access-1');
  });

  it('on 401 refreshes once and retries the original request with the new token and body', async () => {
    const refreshFetch = vi.fn().mockResolvedValue(json(session(2)));
    const store = new SessionStore(memoryStore(), '/api/v1', refreshFetch);
    store.set(session(1));
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(json({ error: { code: 'TOKEN_EXPIRED', message: 'expired' } }, 401))
      .mockResolvedValueOnce(json({ id: 'v1' }, 201));
    const res = await authenticatedFetch(
      store,
      fetchImpl,
    )(
      new Request('http://x/api/v1/vehicles', {
        method: 'POST',
        body: JSON.stringify({ registrationNo: 'MH12AB1234' }),
      }),
    );
    expect(res.status).toBe(201);
    expect(refreshFetch).toHaveBeenCalledTimes(1);
    const retried = fetchImpl.mock.calls[1]?.[0] as Request;
    expect(retried.headers.get('Authorization')).toBe('Bearer access-2');
    await expect(retried.text()).resolves.toBe(JSON.stringify({ registrationNo: 'MH12AB1234' }));
  });

  it('returns the 401 when there is no session to refresh', async () => {
    const store = new SessionStore(memoryStore(), '/api/v1', vi.fn());
    const fetchImpl = vi.fn().mockResolvedValue(json({}, 401));
    const res = await authenticatedFetch(store, fetchImpl)(new Request('http://x/api/v1/me'));
    expect(res.status).toBe(401);
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });
});

describe('safeLocalStorage', () => {
  it('never throws when storage is unavailable', () => {
    const spy = vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new Error('SecurityError');
    });
    expect(safeLocalStorage.get('x')).toBeNull();
    spy.mockRestore();
  });
});
