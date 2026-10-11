import { createContext, useContext } from 'react';
import type { AuthConfig, Membership, Session } from '../lib/api-types.js';

export type AuthStatus = 'restoring' | 'signed_out' | 'signed_in';

export interface AuthState {
  status: AuthStatus;
  session: Session | null;
  /** The membership for the session's active org, if any. */
  activeMembership: Membership | null;
  isStaff: boolean;
  isOwner: boolean;
  /** Which sign-in methods the API offers (password, Google mode). */
  loadAuthConfig(): Promise<AuthConfig>;
  requestOtp(phone: string): Promise<{ expiresInSeconds: number; resendAfterSeconds: number }>;
  verifyOtp(phone: string, code: string): Promise<void>;
  passwordLogin(phone: string, password: string): Promise<void>;
  signup(input: { phone: string; code: string; password: string; name?: string }): Promise<void>;
  resetPassword(input: { phone: string; code: string; password: string }): Promise<void>;
  /** Signs in when the Google account is linked; otherwise a phone must be verified first. */
  googleSignIn(idToken: string): Promise<GoogleOutcome>;
  googleLink(input: { linkToken: string; phone: string; code: string }): Promise<void>;
  createOrg(name: string, kind: 'fleet' | 'dco'): Promise<void>;
  switchOrg(orgId: string): Promise<void>;
  logout(): Promise<void>;
}

export type GoogleOutcome =
  | { status: 'signed_in' }
  | { status: 'phone_required'; linkToken: string; email: string | null; name: string | null };

export const AuthContext = createContext<AuthState | null>(null);

export function useAuth(): AuthState {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used inside <AuthProvider>');
  return context;
}
