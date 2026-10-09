import type { MembershipRole } from '@taxcy/contracts';

/** Who is calling. Set on the request by the auth guard from a verified access token. */
export interface AuthContext {
  userId: string;
  orgId: string | null;
  roles: MembershipRole[];
}

/** Auth for routes that require an active org; the guard guarantees orgId is set. */
export interface TenantAuth extends AuthContext {
  orgId: string;
}

export function hasRole(auth: AuthContext, ...roles: MembershipRole[]): boolean {
  return auth.roles.some((r) => roles.includes(r));
}
