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

const OtpCode = z.string().regex(/^\d{6}$/, 'Expected a 6-digit code');
export const Password = z
  .string()
  .min(8, 'Use at least 8 characters')
  .max(128, 'Use at most 128 characters');

/** The device a session is for (same fields as OTP login). */
const DeviceFields = {
  deviceId: Id,
  platform: DevicePlatform,
  appVersion: z.string().max(40).optional(),
};

export const GoogleSignInResult = z.discriminatedUnion('status', [
  z.object({ status: z.literal('signed_in'), session: Session }),
  /**
   * First Google sign-in: the Google account isn't linked to a phone yet. Verify a
   * phone with an SMS code and send linkToken to /auth/google/link (valid 10 minutes).
   */
  z.object({
    status: z.literal('phone_required'),
    linkToken: z.string(),
    email: z.string().nullable(),
    name: z.string().nullable(),
  }),
]);
export type GoogleSignInResult = z.infer<typeof GoogleSignInResult>;

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
      code: OtpCode,
      ...DeviceFields,
    }),
    response: Session,
  }),
  authConfig: defineRoute({
    method: 'GET',
    path: '/auth/config',
    summary: 'Which sign-in methods are available (for login screens)',
    tag: 'auth',
    access: access.public,
    response: z.object({
      password: z.boolean(),
      google: z.object({
        /** google: real Google sign-in; dev: a local stand-in (no Google account needed); off. */
        mode: z.enum(['google', 'dev', 'off']),
        webClientId: z.string().nullable(),
      }),
    }),
  }),
  signup: defineRoute({
    method: 'POST',
    path: '/auth/signup',
    summary:
      'Sign up with phone and password: request a code first (/auth/otp/request), then send it with the password',
    tag: 'auth',
    access: access.public,
    status: 201,
    body: z.object({
      phone: PhoneE164,
      code: OtpCode,
      password: Password,
      name: z.string().trim().min(1).max(100).optional(),
      ...DeviceFields,
    }),
    response: Session,
  }),
  passwordLogin: defineRoute({
    method: 'POST',
    path: '/auth/password/login',
    summary: 'Sign in with phone and password',
    tag: 'auth',
    access: access.public,
    body: z.object({ phone: PhoneE164, password: z.string().min(1).max(128), ...DeviceFields }),
    response: Session,
  }),
  resetPassword: defineRoute({
    method: 'POST',
    path: '/auth/password/reset',
    summary:
      'Set a new password with an SMS code (request one first); signs out every other session',
    tag: 'auth',
    access: access.public,
    body: z.object({ phone: PhoneE164, code: OtpCode, password: Password, ...DeviceFields }),
    response: Session,
  }),
  changePassword: defineRoute({
    method: 'POST',
    path: '/me/password',
    summary: 'Set or change your password (the current one is required if you have one)',
    tag: 'auth',
    access: access.user,
    status: 204,
    body: z.object({ currentPassword: z.string().max(128).optional(), newPassword: Password }),
    response: z.void(),
  }),
  googleSignIn: defineRoute({
    method: 'POST',
    path: '/auth/google',
    summary:
      'Sign in or sign up with a Google ID token. A new Google account must then verify a phone (/auth/google/link)',
    tag: 'auth',
    access: access.public,
    body: z.object({ idToken: z.string().min(10).max(4096), ...DeviceFields }),
    response: GoogleSignInResult,
  }),
  googleLink: defineRoute({
    method: 'POST',
    path: '/auth/google/link',
    summary:
      'Finish a first Google sign-in: verify a phone with an SMS code; the Google account is linked to it',
    tag: 'auth',
    access: access.public,
    body: z.object({
      linkToken: z.string().min(20).max(200),
      phone: PhoneE164,
      code: OtpCode,
      ...DeviceFields,
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
      user: z.object({
        id: Id,
        phone: PhoneE164,
        name: z.string().nullable(),
        email: z.string().nullable(),
        hasPassword: z.boolean(),
        googleLinked: z.boolean(),
      }),
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

export const MemberStatus = z.enum(['invited', 'active', 'suspended']);

/** Someone with access to the org: owners, managers and drivers. */
export const Member = z.object({
  /** The membership id. */
  id: Id,
  userId: Id,
  name: z.string().nullable(),
  phone: PhoneE164,
  roles: z.array(MembershipRole),
  /**
   * 'invited' until their first sign-in. 'suspended' once their last role was taken
   * away; `roles` then still shows that role, for the record.
   */
  status: MemberStatus,
  createdAt: DateTime,
});
export type Member = z.infer<typeof Member>;

const IdParam = z.object({ id: Id });

export const memberRoutes = {
  listMembers: defineRoute({
    method: 'GET',
    path: '/members',
    summary: 'People with access to the org, with their roles',
    tag: 'members',
    access: access.staff,
    response: z.array(Member),
  }),
  inviteManager: defineRoute({
    method: 'POST',
    path: '/members/managers',
    summary:
      'Give someone manager access by phone (managers run trips, alerts and settlements, but cannot change settings or pay rules)',
    tag: 'members',
    access: access.roles('owner'),
    status: 201,
    body: z.object({ name: z.string().trim().min(1).max(100), phone: PhoneE164 }),
    response: Member,
  }),
  removeManager: defineRoute({
    method: 'DELETE',
    path: '/members/{id}/manager',
    summary:
      'Take away manager access. Other roles (e.g. driver) stay; with none left the member is suspended',
    tag: 'members',
    access: access.roles('owner'),
    params: IdParam,
    response: Member,
  }),
};
