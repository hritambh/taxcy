// Enum labels (fuel types, document names, …) live in the translations under `enums`.

/** "98123 45678", "+91 9812345678", "09812345678" → "+919812345678". */
export function normalizeIndianMobile(input: string): string {
  const digits = input.replace(/\D/g, '');
  return `+91${digits.length > 10 ? digits.slice(-10) : digits}`;
}
