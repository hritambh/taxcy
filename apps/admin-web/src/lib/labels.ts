import { PhoneE164 } from '@taxcy/contracts';

// Enum labels (fuel types, document names, …) live in the translations under `enums`.

/** "98123 45678", "+91 9812345678", "09812345678" → "+919812345678". */
export function normalizeIndianMobile(input: string): string {
  const digits = input.replace(/\D/g, '');
  return `+91${digits.length > 10 ? digits.slice(-10) : digits}`;
}

/** The E.164 number for what was typed, or null if it isn't an Indian mobile. */
export function parseIndianMobile(input: string): string | null {
  const candidate = normalizeIndianMobile(input);
  return PhoneE164.safeParse(candidate).success ? candidate : null;
}
