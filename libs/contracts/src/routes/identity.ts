import { z } from 'zod';
import { DateTime, Id, PhoneE164 } from '../common.js';
import { access, defineRoute, MembershipRole } from '../http.js';

export const OrgKind = z.enum(['fleet', 'dco']);
export type OrgKind = z.infer<typeof OrgKind>;

export const DevicePlatform = z.enum(['android', 'ios', 'web']);

export const Membership = z.object({
  orgId: Id,
  orgName: z.string(),
  orgKind: OrgKind,
  roles: z.array(MembershipRole),
});
export type Membership = z.infer<typeof Membership>;

export const Session = z.object({
  accessToken: z.string(),
  accessTokenExpiresAt: DateTime,
  refreshToken: z.string(),
  refreshTokenExpiresAt: DateTime,
  user: z.object({ id: Id, phone: PhoneE164, name: z.string().nullable() }),
  /** The org this access token is scoped to; null until the user creates or joins one. */
  activeOrgId: Id.nullable(),
  memberships: z.array(Membership),
});
export type Session = z.infer<typeof Session>;

const RefreshTokenBody = z.object({ refreshToken: z.string().min(20).max(200) });

export const identityRoutes = {
  requestOtp: defineRoute({
    method: 'POST',
    path: '/auth/otp/request',
    summary: 'Send a one-time login code by SMS',
    tag: 'auth',
    access: access.public,
    status: 202,
    body: z.object({ phone: PhoneE164 }),
    response: z.object({
      expiresInSeconds: z.number().int(),
      resendAfterSeconds: z.number().int(),
    }),
  }),
  verifyOtp: defineRoute({
    method: 'POST',
    path: '/auth/otp/verify',
    summary: 'Exchange a login code for a session (creates the user on first login)',
    tag: 'auth',
    access: access.public,
    body: z.object({
      phone: PhoneE164,
      code: z.string().regex(/^\d{6}$/, 'Expected a 6-digit code'),
      deviceId: Id,
      platform: DevicePlatform,
      appVersion: z.string().max(40).optional(),
    }),
    response: Session,
  }),
  refresh: defineRoute({
    method: 'POST',
    path: '/auth/refresh',
    summary: 'Rotate the refresh token and get a new access token',
    tag: 'auth',
    access: access.public,
    body: RefreshTokenBody,
    response: Session,
  }),
  logout: defineRoute({
    method: 'POST',
    path: '/auth/logout',
    summary: 'Revoke the refresh token (and every token rotated from it)',
    tag: 'auth',
    access: access.public,
    status: 204,
    body: RefreshTokenBody,
    response: z.void(),
  }),
  switchOrg: defineRoute({
    method: 'POST',
    path: '/auth/switch-org',
    summary: 'Get a session scoped to another org you belong to',
    tag: 'auth',
    access: access.user,
    body: RefreshTokenBody.extend({ orgId: Id }),
    response: Session,
  }),
  me: defineRoute({
    method: 'GET',
    path: '/me',
    summary: 'The signed-in user and their memberships',
    tag: 'auth',
    access: access.user,
    response: z.object({
      user: z.object({ id: Id, phone: PhoneE164, name: z.string().nullable() }),
      activeOrgId: Id.nullable(),
      roles: z.array(MembershipRole),
      memberships: z.array(Membership),
    }),
  }),
  updateMe: defineRoute({
    method: 'PATCH',
    path: '/me',
    summary: 'Update your profile',
    tag: 'auth',
    access: access.user,
    body: z.object({ name: z.string().trim().min(1).max(100) }),
    response: z.object({ id: Id, phone: PhoneE164, name: z.string().nullable() }),
  }),
  createOrg: defineRoute({
    method: 'POST',
    path: '/orgs',
    summary: 'Create an organization; you become its owner (and driver, for a DCO)',
    tag: 'auth',
    access: access.user,
    status: 201,
    body: RefreshTokenBody.extend({ name: z.string().trim().min(2).max(100), kind: OrgKind }),
    response: Session,
  }),
};
