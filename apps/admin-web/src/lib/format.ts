import { assertPaise, istBusinessDate } from '@taxcy/domain';
import { i18n, intlLocale } from '../i18n/index.js';

export const IST = 'Asia/Kolkata';

// Intl formatters are costly to build, so one per locale and style is kept.
const cache = new Map<string, Intl.DateTimeFormat | Intl.NumberFormat>();

function dateFormat(name: string, options: Intl.DateTimeFormatOptions): Intl.DateTimeFormat {
  const key = `${intlLocale()}|d|${name}`;
  let format = cache.get(key) as Intl.DateTimeFormat | undefined;
  if (!format) {
    format = new Intl.DateTimeFormat(intlLocale(), options);
    cache.set(key, format);
  }
  return format;
}

function numberFormat(name: string, options: Intl.NumberFormatOptions): Intl.NumberFormat {
  const key = `${intlLocale()}|n|${name}`;
  let format = cache.get(key) as Intl.NumberFormat | undefined;
  if (!format) {
    format = new Intl.NumberFormat(intlLocale(), options);
    cache.set(key, format);
  }
  return format;
}

const DATE_TIME = {
  day: 'numeric',
  month: 'short',
  hour: 'numeric',
  minute: '2-digit',
  hour12: true,
  timeZone: IST,
} as const;
const DATE_LONG = { day: 'numeric', month: 'short', year: 'numeric', timeZone: IST } as const;
const DATE_SHORT = { day: 'numeric', month: 'short', timeZone: IST } as const;
const TIME = { hour: 'numeric', minute: '2-digit', hour12: true, timeZone: IST } as const;
const isCalendarDate = (value: string) => /^\d{4}-\d{2}-\d{2}$/.test(value);

/** "9 Oct, 2:30 pm" in IST. */
export const fmtDateTime = (iso: string | null | undefined): string =>
  iso ? dateFormat('dateTime', DATE_TIME).format(new Date(iso)) : '—';

/** "9 Oct 2026". Calendar dates (YYYY-MM-DD) are shown as written, not shifted by timezone. */
export function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '—';
  return isCalendarDate(iso)
    ? dateFormat('calendar', { ...DATE_LONG, timeZone: 'UTC' }).format(new Date(`${iso}T00:00:00Z`))
    : dateFormat('long', DATE_LONG).format(new Date(iso));
}

/** "9 Oct": an instant in IST, or a calendar date (YYYY-MM-DD) as written. */
export const fmtDayShort = (iso: string): string =>
  isCalendarDate(iso)
    ? dateFormat('dayCalendar', { ...DATE_SHORT, timeZone: 'UTC' }).format(
        new Date(`${iso}T00:00:00Z`),
      )
    : dateFormat('day', DATE_SHORT).format(new Date(iso));

export const fmtTime = (iso: string | null | undefined): string =>
  iso ? dateFormat('time', TIME).format(new Date(iso)) : '—';

/** A whole number with Indian grouping ("48,210"). */
export const fmtNumber = (value: number): string =>
  numberFormat('whole', { maximumFractionDigits: 0 }).format(value);

/** A number with exactly one decimal ("12.5"), as fuel figures are shown. */
export const fmtDecimal1 = (value: number): string =>
  numberFormat('one', { minimumFractionDigits: 1, maximumFractionDigits: 1 }).format(value);

/** Names joined the way the language lists them ("A, B and C"). */
export const fmtList = (items: readonly string[]): string =>
  new Intl.ListFormat(intlLocale(), { type: 'conjunction' }).format(items);

export const fmtKm = (value: number | null | undefined): string =>
  value === null || value === undefined ? '—' : i18n.t('units.km', { value: fmtNumber(value) });

const inr = (paise: number, fractionDigits: 0 | 2): string => {
  assertPaise(paise);
  return numberFormat(`inr${String(fractionDigits)}`, {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  }).format(paise / 100);
};

/** ₹ amount with Indian grouping; whole rupees drop the paise ("₹2,850", "₹712.50"). */
export const fmtInr = (paise: number | null | undefined): string =>
  paise === null || paise === undefined ? '—' : inr(paise, paise % 100 === 0 ? 0 : 2);

/** ₹ amount always with paise ("₹2,850.00"), for ledgers. */
export const fmtInrExact = (paise: number): string => inr(paise, 2);

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
