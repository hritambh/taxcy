import { describe, expect, it } from 'vitest';
import { buildCycles } from './cycles.js';
import { fill } from './test-helpers.js';

describe('buildCycles: single fuel (full tank to full tank)', () => {
  it('worked example: partial fills in between count, the opening fill does not', () => {
    const fills = [
      fill(10_000, 30, true, { id: 'F1' }),
      fill(10_250, 20, false, { id: 'F2' }),
      fill(10_600, 25, true, { id: 'F3' }),
    ];
    const [cycle, ...rest] = buildCycles(fills, 'diesel');
    expect(rest).toEqual([]);
    expect(cycle).toMatchObject({
      openingFillId: 'F1',
      closingFillId: 'F3',
      fillIds: ['F2', 'F3'],
      distanceKm: 600,
      fuelMilli: 45_000,
      metric: 'km_per_unit',
    });
    expect(cycle?.value).toBeCloseTo(13.333, 3);
  });

  it('ignores fills before the first full fill (unknown starting level)', () => {
    const cycles = buildCycles(
      [
        fill(9_000, 10, false),
        fill(9_500, 15, false),
        fill(10_000, 40, true, { id: 'A' }),
        fill(10_500, 40, true, { id: 'B' }),
      ],
      'diesel',
    );
    expect(cycles.map((c) => [c.openingFillId, c.closingFillId, c.fuelMilli])).toEqual([
      ['A', 'B', 40_000],
    ]);
  });

  it('chains consecutive cycles: each closing fill opens the next', () => {
    const cycles = buildCycles(
      [
        fill(0, 40, true, { id: 'A' }),
        fill(500, 40, true, { id: 'B' }),
        fill(950, 30, true, { id: 'C' }),
      ],
      'diesel',
    );
    expect(cycles.map((c) => `${c.openingFillId}->${c.closingFillId}:${c.distanceKm}`)).toEqual([
      'A->B:500',
      'B->C:450',
    ]);
  });

  it('sorts fills that arrive out of order (offline sync)', () => {
    const a = fill(1_000, 40, true, { id: 'A', at: '2026-02-01T05:00:00Z' });
    const b = fill(1_300, 20, false, { id: 'B', at: '2026-02-03T05:00:00Z' });
    const c = fill(1_600, 20, true, { id: 'C', at: '2026-02-05T05:00:00Z' });
    expect(buildCycles([c, a, b], 'diesel')[0]).toMatchObject({
      fillIds: ['B', 'C'],
      distanceKm: 600,
    });
  });

  it('needs two full fills to make a cycle', () => {
    expect(buildCycles([fill(100, 40, true), fill(400, 20, false)], 'diesel')).toEqual([]);
  });

  it('only counts fills of the tracked fuel', () => {
    const cycles = buildCycles(
      [
        fill(0, 10, true, { fuel: 'cng', id: 'A' }),
        fill(100, 5, false, { fuel: 'petrol' }),
        fill(300, 12, true, { fuel: 'cng', id: 'B' }),
      ],
      'cng',
    );
    expect(cycles[0]).toMatchObject({ fillIds: ['B'], fuelMilli: 12_000, distanceKm: 300 });
  });

  it('has no value when the odometer did not increase', () => {
    expect(buildCycles([fill(500, 40, true), fill(500, 40, true)], 'diesel')[0]?.value).toBeNull();
  });
});

describe('buildCycles: bi-fuel cost per km', () => {
  it('worked example: anchors on full CNG fills and counts the cost of every fill in between', () => {
    const cycles = buildCycles(
      [
        fill(50_000, 9, true, { fuel: 'cng', rupees: 800, id: 'C1' }),
        fill(50_180, 10, false, { fuel: 'petrol', rupees: 1_000, id: 'P1' }),
        fill(50_400, 9.5, true, { fuel: 'cng', rupees: 850, id: 'C2' }),
      ],
      'bifuel_cost',
    );
    expect(cycles).toHaveLength(1);
    expect(cycles[0]).toMatchObject({
      openingFillId: 'C1',
      closingFillId: 'C2',
      fillIds: ['P1', 'C2'],
      distanceKm: 400,
      fuelMilli: null,
      costPaise: 185_000,
      metric: 'paise_per_km',
      value: 462.5,
    });
  });

  it('a full petrol tank is not an anchor', () => {
    const cycles = buildCycles(
      [
        fill(0, 9, true, { fuel: 'cng', rupees: 800, id: 'C1' }),
        fill(200, 30, true, { fuel: 'petrol', rupees: 3_000, id: 'P1' }),
        fill(500, 9, true, { fuel: 'cng', rupees: 800, id: 'C2' }),
      ],
      'bifuel_cost',
    );
    expect(cycles.map((c) => c.fillIds)).toEqual([['P1', 'C2']]);
  });
});
