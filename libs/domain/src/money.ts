const inr = new Intl.NumberFormat('en-IN', {
  style: 'currency',
  currency: 'INR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

/** Throws unless `value` is a whole number of paise that is safe to do arithmetic on. */
export function assertPaise(value: number): void {
  if (!Number.isSafeInteger(value)) {
    throw new RangeError(`Expected an integer amount of paise, got ${value}`);
  }
}

/** Formats paise as Indian rupees with lakh/crore grouping, e.g. 12345678 → "₹1,23,456.78". */
export function formatInr(paise: number): string {
  assertPaise(paise);
  return inr.format(paise / 100);
}

const inrWhole = new Intl.NumberFormat('en-IN', {
  style: 'currency',
  currency: 'INR',
  minimumFractionDigits: 0,
  maximumFractionDigits: 0,
});

/** Like formatInr, but whole-rupee amounts drop the paise: 285000 → "₹2,850", 71250 → "₹712.50". */
export function formatInrShort(paise: number): string {
  assertPaise(paise);
  return paise % 100 === 0 ? inrWhole.format(paise / 100) : inr.format(paise / 100);
}
