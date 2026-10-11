import { z } from 'zod';

export const ErrorCode = z.enum([
  'VALIDATION_FAILED',
  'UNAUTHENTICATED',
  'TOKEN_EXPIRED',
  'FORBIDDEN_ROLE',
  'NO_ACTIVE_ORG',
  'NOT_FOUND',
  'ILLEGAL_TRANSITION',
  'TRIP_CANCELLED',
  'TRIP_REASSIGNED',
  'VEHICLE_BUSY',
  'DRIVER_BUSY',
  'CANCELLATION_PENDING',
  'ALREADY_SETTLED',
  'IDEMPOTENCY_CONFLICT',
  'IDEMPOTENCY_KEY_REQUIRED',
  'VERSION_CONFLICT',
  'CONFLICT',
  'FUEL_TYPE_MISMATCH',
  'ODOMETER_BEFORE_START',
  'OTP_INVALID',
  'OTP_EXPIRED',
  /** Wrong phone or password (deliberately doesn't say which). */
  'INVALID_CREDENTIALS',
  /** Signing up a phone that already has a password: log in or reset it instead. */
  'ACCOUNT_EXISTS',
  /** The Google ID token didn't verify (expired, wrong audience, or Google sign-in is off). */
  'GOOGLE_TOKEN_INVALID',
  /** The phone is already linked to a different Google account. */
  'GOOGLE_ACCOUNT_CONFLICT',
  'RATE_LIMITED',
  'UPLOAD_NOT_FOUND',
  'UPLOAD_MISMATCH',
  'INTERNAL',
]);
export type ErrorCode = z.infer<typeof ErrorCode>;

export const ErrorBody = z.object({
  error: z.object({
    code: ErrorCode,
    message: z.string(),
    details: z.unknown().optional(),
    requestId: z.string().optional(),
  }),
});
export type ErrorBody = z.infer<typeof ErrorBody>;
