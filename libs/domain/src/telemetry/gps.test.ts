import { describe, expect, it } from 'vitest';
import { coverage, filterPoints, haversineKm, pathLengthKm, type GpsPoint } from './gps.js';

const PUNE = { lat: 18.5204, lng: 73.8567 };
const MUMBAI = { lat: 19.076, lng: 72.8777 };
const t0 = Date.parse('2026-10-09T03:00:00Z');

/** Points along a straight line from PUNE heading north-west, one every `everySeconds`. */
function track(count: number, everySeconds: number, kmPerStep = 0.5): GpsPoint[] {
  return Array.from({ length: count }, (_, i) => ({
    id: `p${i}`,
    recordedAt: new Date(t0 + i * everySeconds * 1000),
    lat: PUNE.lat + (i * kmPerStep) / 111,
    lng: PUNE.lng,
    accuracyM: 10,
    isMock: false,
  }));
}

describe('haversineKm', () => {
  it('Pune to Mumbai is about 120 km as the crow flies', () => {
    expect(haversineKm(PUNE, MUMBAI)).toBeGreaterThan(115);
    expect(haversineKm(PUNE, MUMBAI)).toBeLessThan(125);
  });

  it('sums a path', () => {
    expect(pathLengthKm(track(11, 30))).toBeCloseTo(5, 1);
  });
});

describe('filterPoints', () => {
  it('drops inaccurate, mock, duplicate and teleporting points', () => {
    const points = track(5, 30);
    const [p0, p1, p2, p3, p4] = points as [GpsPoint, GpsPoint, GpsPoint, GpsPoint, GpsPoint];
    const input: GpsPoint[] = [
      p0,
      { ...p1, accuracyM: 250 },
      { ...p2, isMock: true },
      p3,
      { ...p3, id: 'dup' },
      { ...p4, lat: p4.lat + 1 }, // ~111 km in 30 s
    ];
    const { kept, dropped } = filterPoints(input);
    expect(kept.map((p) => p.id)).toEqual(['p0', 'p3']);
    expect(dropped).toEqual({ inaccurate: 1, mock: 1, duplicate: 1, impossibleSpeed: 1 });
  });

  it('keeps points without an accuracy reading', () => {
    const [p] = track(1, 30);
    if (!p) throw new Error('fixture');
    expect(filterPoints([{ ...p, accuracyM: null }]).kept).toHaveLength(1);
  });
});

describe('coverage', () => {
  it('a point every minute over an hour is fully covered', () => {
    const points = track(61, 60);
    const c = coverage(points, new Date(t0), new Date(t0 + 3_600_000));
    expect(c.coverageRatio).toBeCloseTo(1, 5);
    expect(c.maxGapSeconds).toBe(60);
  });

  it('a 30-minute hole (phone killed the app) halves coverage', () => {
    const points = track(61, 60).filter((_, i) => i <= 15 || i >= 45);
    const c = coverage(points, new Date(t0), new Date(t0 + 3_600_000));
    expect(c.coverageRatio).toBeCloseTo(0.5, 2);
    expect(c.maxGapSeconds).toBe(1_800);
  });

  it('counts the stretch before the first point as uncovered', () => {
    const late = track(31, 60).map((p) => ({
      ...p,
      recordedAt: new Date(p.recordedAt.getTime() + 1_800_000),
    }));
    expect(coverage(late, new Date(t0), new Date(t0 + 3_600_000)).coverageRatio).toBeCloseTo(
      0.5,
      2,
    );
  });

  it('no points means no coverage', () => {
    expect(coverage([], new Date(t0), new Date(t0 + 3_600_000)).coverageRatio).toBe(0);
  });
});
