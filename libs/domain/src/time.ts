export const IST_TIME_ZONE = 'Asia/Kolkata';

// IST is a fixed UTC+05:30 offset with no daylight saving.
const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;

/**
 * The IST calendar date (YYYY-MM-DD) that a UTC instant falls on.
 * Settlement business dates and document expiry dates are IST calendar dates.
 */
export function istBusinessDate(instant: Date): string {
  const ms = instant.getTime();
  if (Number.isNaN(ms)) {
    throw new RangeError('Invalid date');
  }
  return new Date(ms + IST_OFFSET_MS).toISOString().slice(0, 10);
}
