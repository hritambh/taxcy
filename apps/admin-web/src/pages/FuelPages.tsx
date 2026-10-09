import { useState } from 'react';
import { Link, useParams } from 'react-router';
import { FuelChart } from '../components/FuelChart.js';
import { chartPoints } from '../lib/fuel-chart.js';
import {
  Badge,
  Button,
  Card,
  EmptyState,
  Field,
  InlineError,
  Modal,
  PageHeader,
  QueryState,
  Table,
  Td,
  Textarea,
  Th,
} from '../components/ui.js';
import { api, call } from '../lib/api.js';
import type { FuelCycle, FuelFill, VehicleFuelAudit } from '../lib/api-types.js';
import { fmtDate, fmtDateTime, fmtInr, fmtKm, fmtRegistration, humanize } from '../lib/format.js';
import {
  keys,
  useAuditSettings,
  useFuelFills,
  useVehicle,
  useVehicleAudit,
  useVehicles,
} from '../lib/queries.js';
import { useApiMutation } from '../lib/mutations.js';

function metricText(
  audit: Pick<VehicleFuelAudit, 'metric' | 'unitLabel'>,
  value: number | null,
): string {
  if (value === null) return '—';
  return audit.metric === 'paise_per_km'
    ? `₹${(value / 100).toFixed(2)}/km`
    : `${value.toFixed(1)} ${audit.unitLabel}`;
}

function VerdictBadge({ verdict }: { verdict: FuelCycle['verdict'] }) {
  if (verdict === 'flagged') return <Badge tone="danger">⚠ Flagged</Badge>;
  if (verdict === 'invalid') return <Badge tone="warning">◆ Invalid</Badge>;
  return <Badge tone="success">OK</Badge>;
}

function VoidFillModal({ fill, onClose }: { fill: FuelFill | null; onClose: () => void }) {
  const [reason, setReason] = useState('');
  const mutation = useApiMutation(
    (input: { id: string; reason: string }) =>
      call(
        api.POST('/fuel-fills/{id}/void', {
          params: { path: { id: input.id } },
          body: { reason: input.reason },
        }),
      ),
    [keys.fuel, keys.alerts],
  );
  return (
    <Modal
      open={fill !== null}
      onClose={() => {
        setReason('');
        mutation.reset();
        onClose();
      }}
      title="Void this fill"
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>
            Keep it
          </Button>
          <Button
            variant="danger"
            busy={mutation.isPending}
            disabled={!reason.trim()}
            onClick={() => {
              if (!fill) return;
              mutation.mutate(
                { id: fill.id, reason: reason.trim() },
                {
                  onSuccess: () => {
                    setReason('');
                    onClose();
                  },
                },
              );
            }}
          >
            Void fill
          </Button>
        </>
      }
    >
      {fill && (
        <div className="space-y-3 text-sm">
          <p>
            {(fill.quantityMilli / 1000).toFixed(1)} {fill.unit} of {fill.fuel} for{' '}
            {fmtInr(fill.costPaise)} on {fmtDateTime(fill.filledAt)}. The vehicle’s fuel audit is
            recomputed without it.
          </p>
          <Field label="Reason">
            {(props) => (
              <Textarea
                {...props}
                value={reason}
                placeholder="e.g. Typed 60 L instead of 40 L"
                onChange={(e) => {
                  setReason(e.target.value);
                }}
              />
            )}
          </Field>
          <InlineError error={mutation.error} />
        </div>
      )}
    </Modal>
  );
}

/** Chart, cycles and fills for one vehicle; used on the fuel page and the vehicle page. */
export function VehicleFuelPanel({ vehicleId }: { vehicleId: string }) {
  const audit = useVehicleAudit(vehicleId);
  const settings = useAuditSettings();
  const fills = useFuelFills({ vehicleId, includeVoided: true });
  const [voiding, setVoiding] = useState<FuelFill | null>(null);

  return (
    <div className="space-y-4">
      <Card title="Fuel efficiency by cycle">
        <QueryState query={audit}>
          {(a) =>
            a.cycles.length === 0 ? (
              <EmptyState title="No full-tank cycles yet">
                Efficiency is measured between two full-tank fills.
              </EmptyState>
            ) : (
              <>
                <dl className="mb-4 flex flex-wrap gap-6 text-sm">
                  <div>
                    <dt className="text-xs text-slate-500">Usual</dt>
                    <dd className="font-semibold">{metricText(a, a.baseline?.mean ?? null)}</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-slate-500">Cycles in baseline</dt>
                    <dd className="font-semibold">{a.baseline?.cycles ?? 0}</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-slate-500">Audited on</dt>
                    <dd className="font-semibold">
                      {a.metric === 'paise_per_km'
                        ? 'Running cost (petrol + CNG)'
                        : `Efficiency (${humanize(a.track)})`}
                    </dd>
                  </div>
                </dl>
                {settings.data && (
                  <FuelChart
                    points={chartPoints(a, settings.data)}
                    unitLabel={a.unitLabel}
                    higherIsBetter={a.metric === 'km_per_unit'}
                  />
                )}
                <details className="mt-4">
                  <summary className="cursor-pointer text-sm font-medium text-brand-700">
                    Show cycles as a table
                  </summary>
                  <Table className="mt-2">
                    <thead>
                      <tr>
                        <Th>Cycle</Th>
                        <Th align="right">Distance</Th>
                        <Th align="right">Value</Th>
                        <Th align="right">Usual</Th>
                        <Th>Rule</Th>
                        <Th>Verdict</Th>
                      </tr>
                    </thead>
                    <tbody>
                      {[...a.cycles].reverse().map((c) => (
                        <tr key={c.id}>
                          <Td>
                            {fmtDate(c.startedAt)} → {fmtDate(c.endedAt)}
                          </Td>
                          <Td align="right">{fmtKm(c.distanceKm)}</Td>
                          <Td align="right">{metricText(a, c.metricValue)}</Td>
                          <Td align="right">{metricText(a, c.baselineMean)}</Td>
                          <Td>
                            {c.method === 'sigma'
                              ? `${c.deviation?.toFixed(1) ?? '—'}σ`
                              : `${c.deviation?.toFixed(0) ?? '—'}% (new vehicle)`}
                          </Td>
                          <Td>
                            <VerdictBadge verdict={c.verdict} />
                          </Td>
                        </tr>
                      ))}
                    </tbody>
                  </Table>
                </details>
              </>
            )
          }
        </QueryState>
      </Card>

      <Card title="Fuel fills">
        <QueryState query={fills}>
          {(list) =>
            list.length === 0 ? (
              <EmptyState title="No fills recorded" />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <Th>When</Th>
                    <Th>Driver</Th>
                    <Th align="right">Odometer</Th>
                    <Th align="right">Quantity</Th>
                    <Th align="right">Cost</Th>
                    <Th>Tank</Th>
                    <Th>Paid by</Th>
                    <Th />
                  </tr>
                </thead>
                <tbody>
                  {list.map((f) => (
                    <tr
                      key={f.id}
                      className={f.voidedAt ? 'text-slate-400 line-through' : undefined}
                    >
                      <Td>{fmtDateTime(f.filledAt)}</Td>
                      <Td>{f.driverName ?? '—'}</Td>
                      <Td align="right">{fmtKm(f.odometer.typedKm)}</Td>
                      <Td align="right">
                        {(f.quantityMilli / 1000).toFixed(1)} {f.unit} {f.fuel}
                      </Td>
                      <Td align="right">
                        {fmtInr(f.costPaise)}
                        {f.ocrCostPaise !== null && f.ocrCostPaise !== f.costPaise && (
                          <span className="block text-xs text-amber-700 no-underline">
                            receipt: {fmtInr(f.ocrCostPaise)}
                          </span>
                        )}
                      </Td>
                      <Td>
                        {f.isFullTank ? <Badge tone="brand">Full</Badge> : <Badge>Partial</Badge>}
                      </Td>
                      <Td>{humanize(f.paidBy)}</Td>
                      <Td>
                        {!f.voidedAt && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setVoiding(f);
                            }}
                          >
                            Void
                          </Button>
                        )}
                      </Td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            )
          }
        </QueryState>
      </Card>
      <VoidFillModal
        fill={voiding}
        onClose={() => {
          setVoiding(null);
        }}
      />
    </div>
  );
}

function VehicleFuelSummary({ vehicleId }: { vehicleId: string }) {
  const audit = useVehicleAudit(vehicleId);
  if (!audit.data) return <span className="text-xs text-slate-400">…</span>;
  const last = audit.data.cycles.at(-1);
  return (
    <span className="flex items-center gap-2 text-sm">
      {last ? <VerdictBadge verdict={last.verdict} /> : <Badge>No cycles</Badge>}
      <span className="text-slate-600">
        usual {metricText(audit.data, audit.data.baseline?.mean ?? null)}
      </span>
    </span>
  );
}

export function FuelIndexPage() {
  const vehicles = useVehicles();
  return (
    <>
      <PageHeader
        title="Fuel"
        description="Each vehicle is compared with its own history, cycle by cycle (full tank to full tank)."
      />
      <Card>
        <QueryState query={vehicles}>
          {(list) =>
            list.length === 0 ? (
              <EmptyState title="No vehicles yet">
                <Link className="text-brand-700 hover:underline" to="/vehicles">
                  Add a vehicle
                </Link>
              </EmptyState>
            ) : (
              <ul className="divide-y divide-slate-100">
                {list.map((v) => (
                  <li key={v.id}>
                    <Link
                      to={`/fuel/${v.id}`}
                      className="flex flex-wrap items-center justify-between gap-3 px-1 py-3 hover:bg-slate-50"
                    >
                      <span>
                        <span className="font-medium text-slate-900">
                          {fmtRegistration(v.registrationNo)}
                        </span>
                        <span className="ml-2 text-sm text-slate-600">
                          {v.make} {v.model} ·{' '}
                          {humanize(v.fuelType).replace('Petrol cng', 'Petrol + CNG')}
                        </span>
                      </span>
                      <VehicleFuelSummary vehicleId={v.id} />
                    </Link>
                  </li>
                ))}
              </ul>
            )
          }
        </QueryState>
      </Card>
    </>
  );
}

export function VehicleFuelPage() {
  const { vehicleId = '' } = useParams();
  const vehicle = useVehicle(vehicleId);
  return (
    <>
      <PageHeader
        title={vehicle.data ? `Fuel · ${fmtRegistration(vehicle.data.registrationNo)}` : 'Fuel'}
        description={vehicle.data ? `${vehicle.data.make} ${vehicle.data.model}` : undefined}
        actions={
          <Link className="text-sm text-brand-700 hover:underline" to={`/vehicles/${vehicleId}`}>
            Vehicle details
          </Link>
        }
      />
      <VehicleFuelPanel vehicleId={vehicleId} />
    </>
  );
}
