import type { DocumentRow, Vehicle } from './api-types.js';

export const FUEL_LABELS: Record<Vehicle['fuelType'], string> = {
  petrol: 'Petrol',
  diesel: 'Diesel',
  cng: 'CNG',
  petrol_cng: 'Petrol + CNG',
};

export const DOC_NAMES: Record<DocumentRow['docType'], string> = {
  rc: 'Registration (RC)',
  insurance: 'Insurance',
  permit: 'Permit',
  puc: 'Pollution (PUC)',
  driving_licence: 'Driving licence',
};

/** "98123 45678", "+91 9812345678", "09812345678" → "+919812345678". */
export function normalizeIndianMobile(input: string): string {
  const digits = input.replace(/\D/g, '');
  return `+91${digits.length > 10 ? digits.slice(-10) : digits}`;
}
