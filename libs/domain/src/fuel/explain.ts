import { formatInr, formatInrShort } from '../money.js';
import { IST_TIME_ZONE } from '../time.js';
import type { Cycle } from './cycles.js';
import type { Evaluation } from './evaluate.js';
import type { FuelKind, VehicleFuelType } from './types.js';

export interface VehicleLabel {
  registrationNo: string;
  model: string;
  fuelType: VehicleFuelType;
}

const FUEL_NAMES: Record<VehicleFuelType, string> = {
  petrol: 'petrol',
  diesel: 'diesel',
  cng: 'CNG',
  petrol_cng: 'petrol + CNG',
};
const UNIT: Record<FuelKind, string> = { petrol: 'L', diesel: 'L', cng: 'kg' };

const day = new Intl.DateTimeFormat('en-IN', {
  day: 'numeric',
  month: 'short',
  timeZone: IST_TIME_ZONE,
});
const km = new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 });
const one = (n: number) => n.toFixed(1);
const roundRupees = (paise: number, toNearest: number) =>
  Math.round(paise / 100 / toNearest) * toNearest * 100;

function andList(names: readonly string[]): string {
  if (names.length <= 1) return names[0] ?? '';
  return `${names.slice(0, -1).join(', ')} and ${names.at(-1) ?? ''}`;
}

/**
 * The title and explanation a fleet owner sees for a flagged fuel cycle. Plain
 * language, concrete numbers, and what to check next.
 */
export function explainFuelCycle(input: {
  cycle: Cycle;
  evaluation: Evaluation;
  vehicle: VehicleLabel;
  /** Drivers who logged fills in the cycle. */
  driverNames: readonly string[];
  /** Bi-fuel only: how much of the cycle's cost was petrol. */
  petrolCostPaise?: number;
}): { title: string; explanation: string } {
  const { cycle, evaluation, vehicle } = input;
  const label = `${vehicle.registrationNo} (${vehicle.model}, ${FUEL_NAMES[vehicle.fuelType]})`;
  const period = `Between ${day.format(cycle.startedAt)} and ${day.format(cycle.endedAt)}`;
  const worse = Math.round(evaluation.percentWorse ?? 0);
  const names = andList(input.driverNames);
  const who = names
    ? ` Fills in this period were logged by ${names}${names.endsWith('.') ? '' : '.'}`
    : '';

  if (cycle.metric === 'paise_per_km') {
    const perKm = (paise: number) => `${formatInr(Math.round(paise))}/km`;
    const petrol =
      input.petrolCostPaise && input.petrolCostPaise > 0
        ? ` ${formatInrShort(input.petrolCostPaise)} of that was petrol.`
        : '';
    return {
      title: `${label} cost more to run than usual`,
      explanation:
        `${period} it ran ${km.format(cycle.distanceKm)} km for ${formatInrShort(cycle.costPaise)} of fuel, ` +
        `which is ${perKm(cycle.value ?? 0)}. This car usually costs about ${perKm(evaluation.baselineMean)}, ` +
        `so this is ${worse}% more than normal.${petrol}${who} ` +
        'Check whether the car was run on petrol unnecessarily, and check the receipts.',
    };
  }

  const fuel = cycle.track === 'bifuel_cost' ? 'cng' : cycle.track;
  const unit = UNIT[fuel];
  const usedUnits = (cycle.fuelMilli ?? 0) / 1000;
  const expectedUnits = cycle.distanceKm / evaluation.baselineMean;
  const extraUnits = Math.max(usedUnits - expectedUnits, 0);
  const pricePerUnit = usedUnits > 0 ? cycle.costPaise / usedUnits : 0;
  const extraCost = roundRupees(extraUnits * pricePerUnit, 10);
  return {
    title: `${label} used more fuel than usual`,
    explanation:
      `${period} it ran ${km.format(cycle.distanceKm)} km on ${one(usedUnits)} ${unit} of ${FUEL_NAMES[fuel]}, ` +
      `which is ${one(cycle.value ?? 0)} km/${unit}. This car usually does about ${one(evaluation.baselineMean)} km/${unit}, ` +
      `so this is ${worse}% worse than normal. That's roughly ${one(extraUnits)} ${unit} ` +
      `(about ${formatInrShort(extraCost)}) more ${FUEL_NAMES[fuel]} than expected.${who} ` +
      'Check the receipts and odometer photos.',
  };
}

const INVALID_TEXT = {
  odometer_not_increasing:
    'The odometer reading at the closing fill is not higher than at the opening fill.',
  distance_too_long:
    'More than 3,000 km passed between two full-tank fills, so some fills were probably not logged.',
  implausibly_good:
    'The efficiency is far better than this car normally manages, which usually means a fill was not logged.',
  no_fuel: 'No fuel was recorded between the two full-tank fills.',
} as const;

export function explainInvalidCycle(reason: keyof typeof INVALID_TEXT): string {
  return INVALID_TEXT[reason];
}
