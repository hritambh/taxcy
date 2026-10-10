import { useQueryClient } from '@tanstack/react-query';
import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react';
import { api, call, sessionStore } from '../lib/api.js';
import type { Session } from '../lib/api-types.js';
import { ApiError } from '../lib/errors.js';
import { AuthContext, type AuthState, type AuthStatus } from './context.js';

function requireRefreshToken(): string {
  const token = sessionStore.refreshToken;
  // Shown through errorMessage(), which words UNAUTHENTICATED in the user's language.
  if (!token) throw new ApiError(401, 'UNAUTHENTICATED', 'Your session has ended; sign in again.');
  return token;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient();
  const [session, setSession] = useState<Session | null>(sessionStore.current);
  const [status, setStatus] = useState<AuthStatus>(() =>
    sessionStore.current ? 'signed_in' : sessionStore.refreshToken ? 'restoring' : 'signed_out',
  );

  useEffect(
    () =>
      sessionStore.subscribe((next) => {
        setSession(next);
        setStatus(next ? 'signed_in' : 'signed_out');
      }),
    [],
  );

  // Restore the session from the stored refresh token on first load.
  useEffect(() => {
    if (sessionStore.current || !sessionStore.refreshToken) return;
    void sessionStore.refresh().then((restored) => {
      if (!restored) setStatus('signed_out');
    });
  }, []);

  const adopt = useCallback(
    (next: Session) => {
      // A different org means different data: drop everything cached for the old one.
      if (next.activeOrgId !== sessionStore.current?.activeOrgId) queryClient.clear();
      sessionStore.set(next);
    },
    [queryClient],
  );

  const value = useMemo<AuthState>(() => {
    const activeMembership =
      session?.memberships.find((m) => m.orgId === session.activeOrgId) ?? null;
    const roles = activeMembership?.roles ?? [];
    return {
      status,
      session,
      activeMembership,
      isStaff: roles.includes('owner') || roles.includes('manager'),
      isOwner: roles.includes('owner'),
      requestOtp: (phone) => call(api.POST('/auth/otp/request', { body: { phone } })),
      async verifyOtp(phone, code) {
        adopt(
          await call(
            api.POST('/auth/otp/verify', {
              body: {
                phone,
                code,
                deviceId: sessionStore.deviceId,
                platform: 'web',
                appVersion: 'admin-web',
              },
            }),
          ),
        );
      },
      async createOrg(name, kind) {
        adopt(
          await call(
            api.POST('/orgs', { body: { name, kind, refreshToken: requireRefreshToken() } }),
          ),
        );
      },
      async switchOrg(orgId) {
        adopt(
          await call(
            api.POST('/auth/switch-org', { body: { orgId, refreshToken: requireRefreshToken() } }),
          ),
        );
      },
      async logout() {
        queryClient.clear();
        await sessionStore.logout();
      },
    };
  }, [adopt, queryClient, session, status]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
