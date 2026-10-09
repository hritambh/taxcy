export type DistanceVerdict = 'ok' | 'flagged' | 'inconclusive';

export interface OdoGpsInput {
  odometerKm: number;
  gpsKm: number;
  coverageRatio: number;
  pointsUsed: number;
  /** Allowed excess of odometer over GPS distance, in percent. Default 10. */
  tolerancePct: number;
  /** Below this coverage the GPS distance can't be trusted. Default 0.7. */
  minCoverage?: number;
  minPoints?: number;
}

export interface OdoGpsResult {
  result: DistanceVerdict;
  /** How much the odometer distance exceeds GPS distance, in percent of GPS distance. */
  excessPct: number | null;
  severity: 'warning' | 'critical' | null;
}

/**
 * Flags a trip whose odometer distance exceeds the GPS-recorded distance by more
 * than the tolerance. With poor GPS coverage (phones killing background location)
 * the GPS distance undercounts, so the result is `inconclusive` rather than a false
 * accusation.
 */
export function odoGpsVerdict(input: OdoGpsInput): OdoGpsResult {
  const minCoverage = input.minCoverage ?? 0.7;
  const minPoints = input.minPoints ?? 20;
  if (input.coverageRatio < minCoverage || input.pointsUsed < minPoints || input.gpsKm <= 0) {
    return { result: 'inconclusive', excessPct: null, severity: null };
  }
  const excessPct = ((input.odometerKm - input.gpsKm) / input.gpsKm) * 100;
  if (excessPct <= input.tolerancePct) return { result: 'ok', excessPct, severity: null };
  return {
    result: 'flagged',
    excessPct,
    severity: excessPct > input.tolerancePct * 2 ? 'critical' : 'warning',
  };
}

export function explainOdoGps(input: {
  tripLabel: string;
  odometerKm: number;
  gpsKm: number;
  excessPct: number;
  tolerancePct: number;
}): { title: string; explanation: string } {
  return {
    title: `${input.tripLabel} shows more km on the odometer than the GPS route`,
    explanation:
      `The odometer readings say ${input.odometerKm} km, but the phone's GPS recorded ${Math.round(input.gpsKm)} km. ` +
      `The odometer distance is ${Math.round(input.excessPct)}% higher; the allowed difference is ${input.tolerancePct}%. ` +
      'Check the start and end odometer photos.',
  };
}
