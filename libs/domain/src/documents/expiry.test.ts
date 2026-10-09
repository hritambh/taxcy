import { describe, expect, it } from 'vitest';
import { daysUntil, expiryBucket, expirySeverity, explainExpiry } from './expiry.js';

const today = '2026-10-09';

describe('expiryBucket (thresholds 30/7/1)', () => {
  it.each<[string, number | 'expired' | null]>([
    ['2026-11-30', null],
    ['2026-11-08', 30],
    ['2026-10-17', 30],
    ['2026-10-16', 7],
    ['2026-10-11', 7],
    ['2026-10-10', 1],
    ['2026-10-09', 1],
    ['2026-10-08', 'expired'],
  ])('expires %s → %s', (expiresOn, bucket) => {
    expect(expiryBucket(expiresOn, today, [30, 7, 1])).toBe(bucket);
  });

  it('works with custom thresholds in any order', () => {
    expect(expiryBucket('2026-10-20', today, [1, 15])).toBe(15);
  });

  it('counts days across month and year ends', () => {
    expect(daysUntil('2027-01-01', '2026-12-31')).toBe(1);
    expect(daysUntil('2028-03-01', '2028-02-28')).toBe(2);
  });
});

describe('expirySeverity', () => {
  it.each([
    [30, 'info'],
    [7, 'warning'],
    [1, 'critical'],
    ['expired', 'critical'],
  ] as const)('%s → %s', (bucket, severity) => {
    expect(expirySeverity(bucket)).toBe(severity);
  });
});

describe('explainExpiry', () => {
  it('upcoming', () => {
    expect(
      explainExpiry({
        docType: 'insurance',
        subject: 'MH12 AB 1234',
        expiresOn: '2026-10-14',
        today,
      }),
    ).toEqual({
      title: 'Insurance for MH12 AB 1234 expires in 5 days',
      explanation:
        'Insurance for MH12 AB 1234 expires on 14 Oct 2026. Renew it and upload the new copy before then.',
    });
  });

  it('tomorrow and today', () => {
    expect(
      explainExpiry({ docType: 'puc', subject: 'X', expiresOn: '2026-10-10', today }).title,
    ).toMatch(/expires tomorrow$/);
    expect(
      explainExpiry({ docType: 'puc', subject: 'X', expiresOn: '2026-10-09', today }).title,
    ).toMatch(/expires today$/);
  });

  it('expired', () => {
    expect(
      explainExpiry({
        docType: 'driving_licence',
        subject: 'Ramesh Kumar',
        expiresOn: '2026-10-01',
        today,
      }).title,
    ).toBe('Driving licence for Ramesh Kumar has expired');
  });
});
