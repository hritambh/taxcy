export type DocType = 'rc' | 'insurance' | 'permit' | 'puc' | 'driving_licence';
export type ExpiryBucket = 'expired' | number;

const DAY_MS = 86_400_000;

/** Whole days from `today` to `expiresOn` (both IST calendar dates, YYYY-MM-DD). */
export function daysUntil(expiresOn: string, today: string): number {
  return Math.round(
    (Date.parse(`${expiresOn}T00:00:00Z`) - Date.parse(`${today}T00:00:00Z`)) / DAY_MS,
  );
}

/**
 * Which alert a document is due for today: the tightest threshold it's within
 * (e.g. 7 when 3–7 days remain with thresholds 30/7/1), 'expired' once past the
 * expiry date, or null when no threshold applies yet. A document is still valid on
 * its expiry date (0 days left counts as the last-day bucket).
 */
export function expiryBucket(
  expiresOn: string,
  today: string,
  thresholds: readonly number[],
): ExpiryBucket | null {
  const daysLeft = daysUntil(expiresOn, today);
  if (daysLeft < 0) return 'expired';
  const within = [...thresholds].sort((a, b) => a - b).find((t) => daysLeft <= t);
  return within ?? null;
}

export function expirySeverity(bucket: ExpiryBucket): 'info' | 'warning' | 'critical' {
  if (bucket === 'expired' || bucket <= 1) return 'critical';
  return bucket <= 7 ? 'warning' : 'info';
}

const DOC_NAMES: Record<DocType, string> = {
  rc: 'Registration certificate (RC)',
  insurance: 'Insurance',
  permit: 'Permit',
  puc: 'Pollution certificate (PUC)',
  driving_licence: 'Driving licence',
};

export function explainExpiry(input: {
  docType: DocType;
  /** e.g. "MH12 AB 1234" or "Ramesh Kumar". */
  subject: string;
  expiresOn: string;
  today: string;
}): { title: string; explanation: string } {
  const name = DOC_NAMES[input.docType];
  const days = daysUntil(input.expiresOn, input.today);
  const date = new Date(`${input.expiresOn}T00:00:00Z`).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    timeZone: 'UTC',
  });
  if (days < 0) {
    return {
      title: `${name} for ${input.subject} has expired`,
      explanation: `${name} for ${input.subject} expired on ${date}. Operating without it risks fines and insurance claims being rejected. Renew it and upload the new copy.`,
    };
  }
  const when = days === 0 ? 'today' : days === 1 ? 'tomorrow' : `in ${days} days`;
  return {
    title: `${name} for ${input.subject} expires ${when}`,
    explanation: `${name} for ${input.subject} expires on ${date}. Renew it and upload the new copy before then.`,
  };
}
