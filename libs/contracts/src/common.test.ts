import { describe, expect, it } from 'vitest';
import { Id, Instant, Paise, PhoneE164 } from './common.js';

describe('PhoneE164', () => {
  it.each(['+919812345678', '+916000000000'])('accepts %s', (phone) => {
    expect(PhoneE164.safeParse(phone).success).toBe(true);
  });

  it.each(['9812345678', '+91981234567', '+915812345678', '+14155550100', '+91 98123 45678'])(
    'rejects %s',
    (phone) => {
      expect(PhoneE164.safeParse(phone).success).toBe(false);
    },
  );
});

describe('Paise', () => {
  it('accepts whole non-negative amounts', () => {
    expect(Paise.parse(350000)).toBe(350000);
  });

  it.each([-1, 10.5, Number.MAX_SAFE_INTEGER + 1])('rejects %s', (value) => {
    expect(Paise.safeParse(value).success).toBe(false);
  });
});

describe('Id', () => {
  it('accepts a UUID and rejects other strings', () => {
    expect(Id.safeParse('0199c7a2-5b7e-7c3d-9f00-1a2b3c4d5e6f').success).toBe(true);
    expect(Id.safeParse('trip-1').success).toBe(false);
  });
});

describe('Instant', () => {
  it('requires an explicit offset', () => {
    expect(Instant.safeParse('2026-10-09T08:30:00Z').success).toBe(true);
    expect(Instant.safeParse('2026-10-09T14:00:00+05:30').success).toBe(true);
    expect(Instant.safeParse('2026-10-09T08:30:00').success).toBe(false);
  });
});
