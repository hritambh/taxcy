import type { AuditSettings, FuelCycle, VehicleFuelAudit } from './api-types.js';

export interface ChartPoint {
  t: number;
  value: number;
  /** The range this cycle was judged against: mean ± kσ, or mean ± p% for a new vehicle. */
  band: [number, number] | null;
  verdict: FuelCycle['verdict'];
  method: FuelCycle['method'];
  distanceKm: number;
  baselineMean: number | null;
}

/** Converts cycles to chart points in display units (₹/km rather than paise/km for cost tracking). */
export function chartPoints(
  audit: Pick<VehicleFuelAudit, 'metric' | 'cycles'>,
  settings: Pick<AuditSettings, 'fuelKSigma' | 'fuelPctThreshold'>,
): ChartPoint[] {
  const scale = audit.metric === 'paise_per_km' ? 0.01 : 1;
  return audit.cycles
    .filter((c) => c.metricValue !== null)
    .map((c) => {
      let band: [number, number] | null = null;
      if (c.baselineMean !== null) {
        const half =
          c.method === 'sigma' && c.baselineStd !== null
            ? settings.fuelKSigma * c.baselineStd
            : (c.baselineMean * settings.fuelPctThreshold) / 100;
        band = [(c.baselineMean - half) * scale, (c.baselineMean + half) * scale];
      }
      return {
        t: new Date(c.endedAt).getTime(),
        value: (c.metricValue ?? 0) * scale,
        band,
        verdict: c.verdict,
        method: c.method,
        distanceKm: c.distanceKm,
        baselineMean: c.baselineMean === null ? null : c.baselineMean * scale,
      };
    });
}
