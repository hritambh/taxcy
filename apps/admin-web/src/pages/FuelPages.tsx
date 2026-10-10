import { useState } from 'react';
import { useTranslation } from 'react-i18next';
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
import { i18n } from '../i18n/index.js';
import { api, call } from '../lib/api.js';
import type { FuelCycle, FuelFill, VehicleFuelAudit } from '../lib/api-types.js';
import {
  fmtDate,
  fmtDateTime,
  fmtDecimal1,
  fmtInr,
  fmtInrExact,
  fmtKm,
  fmtNumber,
  fmtRegistration,
} from '../lib/format.js';
import {
  keys,
  useAuditSettings,
  useFuelFills,
  useVehicle,
  useVehicleAudit,
  useVehicles,
} from '../lib/queries.js';
import { useApiMutation } from '../lib/mutations.js';

/** Litres, except CNG which is weighed in kg. */
const auditUnit = (audit: Pick<VehicleFuelAudit, 'track'>): 'L' | 'kg' =>
  audit.track === 'cng' ? 'kg' : 'L';

/** A cycle figure in the audit's metric: "₹4.62/km" or "12.5 km/L". */
function metricText(
  audit: Pick<VehicleFuelAudit, 'metric' | 'track'>,
  value: number | null,
): string {
  if (value === null) return '—';
  return audit.metric === 'paise_per_km'
    ? i18n.t('units.perKm', { amount: fmtInrExact(Math.round(value)) })
    : i18n.t('units.kmPerUnit', {
        value: fmtDecimal1(value),
        unit: i18n.t(`units.${auditUnit(audit)}`),
      });
}

function VerdictBadge({ verdict }: { verdict: FuelCycle['verdict'] }) {
  const { t } = useTranslation();
  if (verdict === 'flagged') return <Badge tone="danger">{t('fleet.fuel.verdict.flagged')}</Badge>;
  if (verdict === 'invalid') return <Badge tone="warning">{t('fleet.fuel.verdict.invalid')}</Badge>;
  return <Badge tone="success">{t('fleet.fuel.verdict.ok')}</Badge>;
}

function VoidFillModal({ fill, onClose }: { fill: FuelFill | null; onClose: () => void }) {
  const { t } = useTranslation();
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
      title={t('fleet.fuel.voidTitle')}
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>
            {t('fleet.fuel.keepIt')}
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
            {t('fleet.fuel.voidFill')}
          </Button>
        </>
      }
    >
      {fill && (
        <div className="space-y-3 text-sm">
          <p>
            {t('fleet.fuel.voidSummary', {
              quantity: t('units.quantity', {
                value: fmtDecimal1(fill.quantityMilli / 1000),
                unit: t(`units.${fill.unit}`),
              }),
              fuel: t(`alerts.fuelName.${fill.fuel}`),
              cost: fmtInr(fill.costPaise),
              when: fmtDateTime(fill.filledAt),
            })}
          </p>
          <Field label={t('fleet.fuel.reason')}>
            {(props) => (
              <Textarea
                {...props}
                value={reason}
                placeholder={t('fleet.fuel.reasonPlaceholder')}
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
  const { t } = useTranslation();
  const audit = useVehicleAudit(vehicleId);
  const settings = useAuditSettings();
  const fills = useFuelFills({ vehicleId, includeVoided: true });
  const [voiding, setVoiding] = useState<FuelFill | null>(null);

  return (
    <div className="space-y-4">
      <Card title={t('fleet.fuel.efficiencyByCycle')}>
        <QueryState query={audit}>
          {(a) =>
            a.cycles.length === 0 ? (
              <EmptyState title={t('fleet.fuel.noFullTankCycles')}>
                {t('fleet.fuel.noFullTankCyclesHint')}
              </EmptyState>
            ) : (
              <>
                <dl className="mb-4 flex flex-wrap gap-6 text-sm">
                  <div>
                    <dt className="text-xs text-slate-500">{t('fleet.fuel.usual')}</dt>
                    <dd className="font-semibold">{metricText(a, a.baseline?.mean ?? null)}</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-slate-500">{t('fleet.fuel.cyclesInBaseline')}</dt>
                    <dd className="font-semibold">{fmtNumber(a.baseline?.cycles ?? 0)}</dd>
                  </div>
                  <div>
                    <dt className="text-xs text-slate-500">{t('fleet.fuel.auditedOn')}</dt>
                    <dd className="font-semibold">
                      {a.metric === 'paise_per_km'
                        ? t('fleet.fuel.runningCost')
                        : t('fleet.fuel.efficiencyOf', { track: t(`enums.auditTrack.${a.track}`) })}
                    </dd>
                  </div>
                </dl>
                {settings.data && (
                  <FuelChart
                    points={chartPoints(a, settings.data)}
                    metric={a.metric}
                    unit={auditUnit(a)}
                    higherIsBetter={a.metric === 'km_per_unit'}
                  />
                )}
                <details className="mt-4">
                  <summary className="cursor-pointer text-sm font-medium text-brand-700">
                    {t('fleet.fuel.showCycles')}
                  </summary>
                  <Table className="mt-2">
                    <thead>
                      <tr>
                        <Th>{t('fleet.fuel.cycleCol.cycle')}</Th>
                        <Th align="right">{t('fleet.fuel.cycleCol.distance')}</Th>
                        <Th align="right">{t('fleet.fuel.cycleCol.value')}</Th>
                        <Th align="right">{t('fleet.fuel.cycleCol.usual')}</Th>
                        <Th>{t('fleet.fuel.cycleCol.rule')}</Th>
                        <Th>{t('fleet.fuel.cycleCol.verdict')}</Th>
                      </tr>
                    </thead>
                    <tbody>
                      {[...a.cycles].reverse().map((c) => (
                        <tr key={c.id}>
                          <Td>
                            {t('common.route', {
                              from: fmtDate(c.startedAt),
                              to: fmtDate(c.endedAt),
                            })}
                          </Td>
                          <Td align="right">{fmtKm(c.distanceKm)}</Td>
                          <Td align="right">{metricText(a, c.metricValue)}</Td>
                          <Td align="right">{metricText(a, c.baselineMean)}</Td>
                          <Td>
                            {c.method === 'sigma'
                              ? t('fleet.fuel.ruleSigma', {
                                  value: c.deviation === null ? '—' : fmtDecimal1(c.deviation),
                                })
                              : t('fleet.fuel.ruleNewVehicle', {
                                  value: c.deviation === null ? '—' : fmtNumber(c.deviation),
                                })}
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

      <Card title={t('fleet.fuel.fills')}>
        <QueryState query={fills}>
          {(list) =>
            list.length === 0 ? (
              <EmptyState title={t('fleet.fuel.noFills')} />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <Th>{t('fleet.fuel.fillCol.when')}</Th>
                    <Th>{t('fleet.fuel.fillCol.driver')}</Th>
                    <Th align="right">{t('fleet.fuel.fillCol.odometer')}</Th>
                    <Th align="right">{t('fleet.fuel.fillCol.quantity')}</Th>
                    <Th align="right">{t('fleet.fuel.fillCol.cost')}</Th>
                    <Th>{t('fleet.fuel.fillCol.tank')}</Th>
                    <Th>{t('fleet.fuel.fillCol.paidBy')}</Th>
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
                        {t('fleet.fuel.fillQuantity', {
                          quantity: t('units.quantity', {
                            value: fmtDecimal1(f.quantityMilli / 1000),
                            unit: t(`units.${f.unit}`),
                          }),
                          fuel: t(`alerts.fuelName.${f.fuel}`),
                        })}
                      </Td>
                      <Td align="right">
                        {fmtInr(f.costPaise)}
                        {f.ocrCostPaise !== null && f.ocrCostPaise !== f.costPaise && (
                          <span className="block text-xs text-amber-700 no-underline">
                            {t('fleet.fuel.receiptAmount', { amount: fmtInr(f.ocrCostPaise) })}
                          </span>
                        )}
                      </Td>
                      <Td>
                        {f.isFullTank ? (
                          <Badge tone="brand">{t('fleet.fuel.fullTank')}</Badge>
                        ) : (
                          <Badge>{t('fleet.fuel.partialTank')}</Badge>
                        )}
                      </Td>
                      <Td>{t(`enums.paidBy.${f.paidBy}`)}</Td>
                      <Td>
                        {!f.voidedAt && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setVoiding(f);
                            }}
                          >
                            {t('fleet.fuel.void')}
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
  const { t } = useTranslation();
  const audit = useVehicleAudit(vehicleId);
  if (!audit.data) return <span className="text-xs text-slate-400">…</span>;
  const last = audit.data.cycles.at(-1);
  return (
    <span className="flex items-center gap-2 text-sm">
      {last ? <VerdictBadge verdict={last.verdict} /> : <Badge>{t('fleet.fuel.noCycles')}</Badge>}
      <span className="text-slate-600">
        {t('fleet.fuel.usualValue', {
          value: metricText(audit.data, audit.data.baseline?.mean ?? null),
        })}
      </span>
    </span>
  );
}

export function FuelIndexPage() {
  const { t } = useTranslation();
  const vehicles = useVehicles();
  return (
    <>
      <PageHeader title={t('nav.fuel')} description={t('fleet.fuel.description')} />
      <Card>
        <QueryState query={vehicles}>
          {(list) =>
            list.length === 0 ? (
              <EmptyState title={t('fleet.fuel.noVehicles')}>
                <Link className="text-brand-700 hover:underline" to="/vehicles">
                  {t('fleet.fuel.addVehicle')}
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
                          {v.make} {v.model} · {t(`enums.fuelType.${v.fuelType}`)}
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
  const { t } = useTranslation();
  const { vehicleId = '' } = useParams();
  const vehicle = useVehicle(vehicleId);
  return (
    <>
      <PageHeader
        title={
          vehicle.data
            ? t('fleet.fuel.vehicleTitle', {
                registrationNo: fmtRegistration(vehicle.data.registrationNo),
              })
            : t('nav.fuel')
        }
        description={vehicle.data ? `${vehicle.data.make} ${vehicle.data.model}` : undefined}
        actions={
          <Link className="text-sm text-brand-700 hover:underline" to={`/vehicles/${vehicleId}`}>
            {t('fleet.fuel.vehicleDetails')}
          </Link>
        }
      />
      <VehicleFuelPanel vehicleId={vehicleId} />
    </>
  );
}
