import { i18n } from '../i18n/index.js';
import type { ReviewItem } from './api-types.js';

const REASON_CODES = [
  'odometer_not_increasing',
  'distance_too_long',
  'implausibly_good',
  'no_fuel',
] as const;

// Review items the API raises with English text only; matched by that text so they
// still read in the user's language. Anything else is shown as sent.
const KNOWN_TEXT = {
  'The odometer could not be read from the photo': 'odometerUnreadable',
  'The receipt could not be read from the photo': 'receiptUnreadable',
  'The phone reported mock (fake) GPS locations during this trip': 'mockTrip',
  'Photo was captured while the phone reported a mock (fake) GPS location': 'mockPhoto',
  'Driver tried to start the trip after it was cancelled': 'orphanStart',
  'Driver tried to end the trip after it was cancelled': 'orphanEnd',
} as const;

const isOneOf = <T extends string>(values: readonly T[], value: unknown): value is T =>
  values.some((v) => v === value);

/** Why an item is in the review queue, in the user's language; null if no reason was given. */
export function reviewReason(context: ReviewItem['context']): string | null {
  const code = context['reasonCode'];
  if (isOneOf(REASON_CODES, code)) return i18n.t(`review.reason.${code}`);
  const text = context['reason'];
  if (typeof text !== 'string') return null;
  const known = Object.entries(KNOWN_TEXT).find(([english]) => english === text)?.[1];
  return known ? i18n.t(`review.reason.${known}`) : text;
}
