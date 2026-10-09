import { formatInr, formatInrShort, istBusinessDate } from '@taxcy/domain';

export const IST = 'Asia/Kolkata';

const dateTime = new Intl.DateTimeFormat('en-IN', {
  day: 'numeric',
  month: 'short',
  hour: 'numeric',
  minute: '2-digit',
  hour12: true,
  timeZone: IST,
});
const dateLong = new Intl.DateTimeFormat('en-IN', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  timeZone: IST,
});
const calendarDate = new Intl.DateTimeFormat('en-IN', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  timeZone: 'UTC',
});
const dateShort = new Intl.DateTimeFormat('en-IN', {
  day: 'numeric',
  month: 'short',
  timeZone: IST,
});
const timeOnly = new Intl.DateTimeFormat('en-IN', {
  hour: 'numeric',
  minute: '2-digit',
  hour12: true,
  timeZone: IST,
});
const whole = new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 });

/** "9 Oct, 2:30 pm" in IST. */
export const fmtDateTime = (iso: string | null | undefined): string =>
  iso ? dateTime.format(new Date(iso)) : '—';

/** "9 Oct 2026". Calendar dates (YYYY-MM-DD) are shown as written, not shifted by timezone. */
export function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '—';
  return /^\d{4}-\d{2}-\d{2}$/.test(iso)
    ? calendarDate.format(new Date(`${iso}T00:00:00Z`))
    : dateLong.format(new Date(iso));
}

export const fmtDayShort = (iso: string): string => dateShort.format(new Date(iso));
export const fmtTime = (iso: string | null | undefined): string =>
  iso ? timeOnly.format(new Date(iso)) : '—';
export const fmtKm = (value: number | null | undefined): string =>
  value === null || value === undefined ? '—' : `${whole.format(value)} km`;

/** ₹ amount; whole rupees drop the paise ("₹2,850", "₹712.50"). */
export const fmtInr = (paise: number | null | undefined): string =>
  paise === null || paise === undefined ? '—' : formatInrShort(paise);

/** ₹ amount always with paise ("₹2,850.00"), for ledgers. */
export const fmtInrExact = (paise: number): string => formatInr(paise);

/** Parses a rupee amount typed by a person ("2,850.5", "₹ 300") into paise; null if invalid. */
export function rupeesToPaise(input: string): number | null {
  const cleaned = input.replace(/[₹,\s]/g, '');
  if (!/^\d+(\.\d{1,2})?$/.test(cleaned)) return null;
  const [rupees = '0', paise = ''] = cleaned.split('.');
  return Number(rupees) * 100 + Number(paise.padEnd(2, '0'));
}

export const paiseToRupeesInput = (paise: number): string =>
  paise % 100 === 0 ? String(paise / 100) : (paise / 100).toFixed(2);

/** Today's IST calendar date (YYYY-MM-DD). */
export const istToday = (now = new Date()): string => istBusinessDate(now);
export const istDaysAgo = (days: number, now = new Date()): string =>
  istBusinessDate(new Date(now.getTime() - days * 86_400_000));

/** A datetime-local value ("2026-10-09T14:30") read as IST → ISO instant. */
export const istLocalToIso = (local: string): string => new Date(`${local}:00+05:30`).toISOString();

/** ISO instant → datetime-local value in IST. */
export const isoToIstLocal = (iso: string): string =>
  new Date(new Date(iso).getTime() + 330 * 60_000).toISOString().slice(0, 16);

/** IST day boundaries of a calendar date, as ISO instants (for API date-range filters). */
export function istDayRange(date: string): { from: string; to: string } {
  const start = new Date(`${date}T00:00:00+05:30`);
  return { from: start.toISOString(), to: new Date(start.getTime() + 86_400_000).toISOString() };
}

/** "driving_licence" → "Driving licence". */
export const humanize = (value: string): string =>
  value.replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase());

/** "MH12AB1234" → "MH 12 AB 1234" for display. */
export function fmtRegistration(reg: string): string {
  const m = /^([A-Z]{2})(\d{1,2})([A-Z]{0,3})(\d{1,4})$/.exec(reg);
  return m ? [m[1], m[2], m[3], m[4]].filter(Boolean).join(' ') : reg;
}

/** Phone numbers as Indians read them: "+91 98123 45678". */
export function fmtPhone(e164: string | null | undefined): string {
  if (!e164) return '—';
  const m = /^\+91(\d{5})(\d{5})$/.exec(e164);
  return m ? `+91 ${m[1] ?? ''} ${m[2] ?? ''}` : e164;
}
