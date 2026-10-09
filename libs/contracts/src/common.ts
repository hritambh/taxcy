import { z } from 'zod';

/** Indian mobile number in E.164 form, e.g. +919812345678. */
export const PhoneE164 = z
  .string()
  .regex(/^\+91[6-9]\d{9}$/, 'Expected an Indian mobile number in E.164 format (+91XXXXXXXXXX)');
export type PhoneE164 = z.infer<typeof PhoneE164>;

/** Money as a non-negative whole number of paise. */
export const Paise = z.number().int().nonnegative().max(Number.MAX_SAFE_INTEGER);
export type Paise = z.infer<typeof Paise>;

/** Client- or server-generated record id; doubles as the idempotency key for offline records. */
export const Id = z.uuid();
export type Id = z.infer<typeof Id>;

/** Timestamp with an explicit offset, e.g. 2026-10-09T08:30:00Z or 2026-10-09T14:00:00+05:30. */
export const Instant = z.iso.datetime({ offset: true });
export type Instant = z.infer<typeof Instant>;
