import { describe, expect, it } from 'vitest';
import { assertPaise, formatInr } from './money.js';

describe('formatInr', () => {
  it.each([
    [0, '₹0.00'],
    [5, '₹0.05'],
    [350000, '₹3,500.00'],
    [12345678, '₹1,23,456.78'],
    [1000000000, '₹1,00,00,000.00'],
    [-25050, '-₹250.50'],
  ])('formats %i paise as %s', (paise, expected) => {
    expect(formatInr(paise)).toBe(expected);
  });

  it('rejects fractional paise', () => {
    expect(() => formatInr(10.5)).toThrow(RangeError);
  });
});

describe('assertPaise', () => {
  it('rejects values beyond the safe integer range', () => {
    expect(() => {
      assertPaise(Number.MAX_SAFE_INTEGER + 1);
    }).toThrow(RangeError);
  });

  it('rejects NaN', () => {
    expect(() => {
      assertPaise(Number.NaN);
    }).toThrow(RangeError);
  });
});
