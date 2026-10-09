import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { runSeed } from '../src/seed/seed.js';
import { startHarness, type Harness } from './harness.js';

let h: Harness;

beforeAll(async () => {
  h = await startHarness();
  await runSeed(h.app);
}, 600_000);

afterAll(async () => {
  await h.close();
});

describe('demo seed', () => {
  it('creates the org, people and vehicles', async () => {
    const org = await h.owner.organization.findFirstOrThrow({ where: { name: 'Sharma Travels' } });
    expect(await h.owner.vehicle.count({ where: { orgId: org.id } })).toBe(3);
    expect(await h.owner.driver.count({ where: { orgId: org.id } })).toBe(3);
    expect(await h.owner.membership.count({ where: { orgId: org.id } })).toBe(5);
  });

  it('produces the alerts the getting-started guide promises', async () => {
    const open = await h.owner.alert.findMany({ where: { status: 'open' } });
    const titles = open.map((a) => `${a.kind}: ${a.title}`);
    expect(titles).toEqual(
      expect.arrayContaining([
        expect.stringMatching(
          /^fuel_efficiency_low: MH12CD5678 \(Dzire, CNG\) used more fuel than usual$/,
        ),
        expect.stringMatching(
          /^odo_gps_mismatch: Trip on .* \(.*MH12AB1234\) shows more km on the odometer than the GPS route$/,
        ),
        expect.stringMatching(/^document_expiring: Insurance for MH12CD5678 expires in 5 days$/),
      ]),
    );
    expect(open.filter((a) => a.kind === 'fuel_efficiency_low')).toHaveLength(1);
  });

  it('has an OCR mismatch waiting in the review queue', async () => {
    const items = await h.owner.reviewItem.findMany({ where: { status: 'open' } });
    expect(items.map((i) => i.kind)).toContain('ocr_mismatch_odometer');
  });

  it('has trips in every state and settles all but the last two days', async () => {
    const byStatus = await h.owner.trip.groupBy({ by: ['status'], _count: { _all: true } });
    const statuses = Object.fromEntries(byStatus.map((s) => [s.status, s._count._all]));
    expect(Object.keys(statuses).sort()).toEqual([
      'assigned',
      'cancelled',
      'created',
      'ended',
      'settled',
      'started',
    ]);
    expect(statuses['settled']).toBeGreaterThan(50);
    expect(await h.owner.settlement.count({ where: { status: 'settled' } })).toBeGreaterThan(60);
  });

  it('is safe to run twice', async () => {
    await runSeed(h.app);
    expect(await h.owner.organization.count({ where: { name: 'Sharma Travels' } })).toBe(1);
  });
});
