import { useQueryClient } from '@tanstack/react-query';
import { chargePaidByDriver, isExtraFareCharge } from '@taxcy/domain';
import { useMemo, useState, type SubmitEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useParams } from 'react-router';
import { RouteMap } from '../components/maps.js';
import { DriverSelect, Photo, VehicleSelect } from '../components/shared.js';
import { TripStatusBadge } from '../components/status.js';
import {
  Badge,
  Button,
  Card,
  EmptyState,
  Field,
  InlineError,
  Input,
  Modal,
  PageHeader,
  QueryState,
  Select,
  Stat,
  Table,
  Td,
  Textarea,
  type Tone,
} from '../components/ui.js';
import { intlLocale } from '../i18n/index.js';
import { en } from '../i18n/locales/en.js';
import { alertText } from '../lib/alert-text.js';
import { api, call, idempotencyKey } from '../lib/api.js';
import type { DistanceCheck, Trip, TripEvent } from '../lib/api-types.js';
import {
  fmtDateTime,
  fmtInr,
  fmtKm,
  fmtNumber,
  fmtPhone,
  fmtRegistration,
  rupeesToPaise,
} from '../lib/format.js';
import {
  keys,
  useAlerts,
  useDistanceCheck,
  useTrip,
  useTripEvents,
  useTripRoute,
} from '../lib/queries.js';
import { useApiMutation } from '../lib/mutations.js';

type OdometerReading = NonNullable<Trip['startOdometer']>;
type Role = Trip['charges'][number]['enteredRole'];
type EventName = keyof typeof en.enums.tripEvent;

const isEventName = (name: string): name is EventName => Object.hasOwn(en.enums.tripEvent, name);

/** A role as it reads mid-sentence ("by the owner"). */
function useRoleName() {
  const { t } = useTranslation();
  return (role: Role) => t(`enums.role.${role}`).toLocaleLowerCase(intlLocale());
}

/** Invalidate everything a trip change can affect. */
function useTripInvalidation(tripId: string) {
  const queryClient = useQueryClient();
  return () =>
    Promise.all([
      queryClient.invalidateQueries({ queryKey: keys.trip(tripId) }),
      queryClient.invalidateQueries({ queryKey: keys.trips }),
      queryClient.invalidateQueries({ queryKey: keys.alerts }),
      queryClient.invalidateQueries({ queryKey: keys.settlements }),
    ]);
}

function AssignModal({ trip, onClose }: { trip: Trip; onClose: () => void }) {
  const { t } = useTranslation();
  const [vehicleId, setVehicleId] = useState(trip.vehicle?.id ?? '');
  const [driverId, setDriverId] = useState(trip.driver?.id ?? '');
  const assign = useApiMutation(
    () =>
      call(
        api.POST('/trips/{id}/assign', {
          params: { path: { id: trip.id }, header: idempotencyKey() },
          body: { vehicleId, driverId },
        }),
      ),
    [keys.trips],
  );
  return (
    <Modal
      open
      onClose={onClose}
      title={trip.vehicle ? t('trips.assign.reassignTitle') : t('trips.assign.assignTitle')}
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>
            {t('common.cancel')}
          </Button>
          <Button
            busy={assign.isPending}
            disabled={!vehicleId || !driverId}
            onClick={() => {
              assign.mutate(undefined, { onSuccess: onClose });
            }}
          >
            {trip.vehicle ? t('trips.assign.reassign') : t('trips.assign.assign')}
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <Field label={t('trips.vehicle')}>
          {(props) => <VehicleSelect {...props} value={vehicleId} onChange={setVehicleId} />}
        </Field>
        <Field label={t('trips.driver')}>
          {(props) => <DriverSelect {...props} value={driverId} onChange={setDriverId} />}
        </Field>
        <p className="text-xs text-slate-500">{t('trips.assign.overlapHint')}</p>
        <InlineError error={assign.error} />
      </div>
    </Modal>
  );
}

function ReasonModal({
  title,
  label,
  confirm,
  busy,
  error,
  onConfirm,
  onClose,
  extra,
}: {
  title: string;
  label: string;
  confirm: string;
  busy: boolean;
  error: unknown;
  onConfirm: (text: string) => void;
  onClose: () => void;
  extra?: React.ReactNode;
}) {
  const { t } = useTranslation();
  const [text, setText] = useState('');
  return (
    <Modal
      open
      onClose={onClose}
      title={title}
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>
            {t('trips.back')}
          </Button>
          <Button
            variant="danger"
            busy={busy}
            disabled={!text.trim()}
            onClick={() => {
              onConfirm(text.trim());
            }}
          >
            {confirm}
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <Field label={label}>
          {(props) => (
            <Textarea
              {...props}
              value={text}
              onChange={(e) => {
                setText(e.target.value);
              }}
            />
          )}
        </Field>
        {extra}
        <InlineError error={error} />
      </div>
    </Modal>
  );
}

function Actions({ trip }: { trip: Trip }) {
  const { t } = useTranslation();
  const invalidate = useTripInvalidation(trip.id);
  const [dialog, setDialog] = useState<'assign' | 'cancel' | null>(null);
  const unassign = useApiMutation(
    () =>
      call(
        api.POST('/trips/{id}/unassign', {
          params: { path: { id: trip.id }, header: idempotencyKey() },
        }),
      ),
    [keys.trips],
  );
  const cancel = useApiMutation(
    (reason: string) =>
      call(
        api.POST('/trips/{id}/cancel', {
          params: { path: { id: trip.id }, header: idempotencyKey() },
          body: { reason },
        }),
      ),
    [keys.trips],
  );
  const can = (c: Trip['allowedCommands'][number]) => trip.allowedCommands.includes(c);

  return (
    <>
      {(can('assign') || can('reassign')) && (
        <Button
          onClick={() => {
            setDialog('assign');
          }}
        >
          {can('assign') ? t('trips.assign.assign') : t('trips.assign.reassign')}
        </Button>
      )}
      {can('unassign') && (
        <Button
          variant="secondary"
          busy={unassign.isPending}
          onClick={() => {
            unassign.mutate(undefined, { onSuccess: () => void invalidate() });
          }}
        >
          {t('trips.assign.unassign')}
        </Button>
      )}
      {can('cancel') && (
        <Button
          variant="secondary"
          onClick={() => {
            setDialog('cancel');
          }}
        >
          {t('trips.cancelTrip')}
        </Button>
      )}
      {unassign.error ? <InlineError error={unassign.error} /> : null}
      {dialog === 'assign' && (
        <AssignModal
          trip={trip}
          onClose={() => {
            setDialog(null);
          }}
        />
      )}
      {dialog === 'cancel' && (
        <ReasonModal
          title={t('trips.cancelTitle')}
          label={t('trips.reason')}
          confirm={t('trips.cancelTrip')}
          busy={cancel.isPending}
          error={cancel.error}
          onClose={() => {
            setDialog(null);
          }}
          onConfirm={(reason) => {
            cancel.mutate(reason, {
              onSuccess: () => {
                setDialog(null);
                void invalidate();
              },
            });
          }}
        />
      )}
    </>
  );
}

function CancellationCard({ trip }: { trip: Trip }) {
  const { t } = useTranslation();
  const roleName = useRoleName();
  const request = trip.cancellationRequest;
  const invalidate = useTripInvalidation(trip.id);
  const [dialog, setDialog] = useState<'approve' | 'reject' | null>(null);
  const [fare, setFare] = useState('0');
  const approve = useApiMutation(
    (input: { cancellationFarePaise: number; note: string }) =>
      call(
        api.POST('/cancellation-requests/{id}/approve', {
          params: { path: { id: request?.id ?? '' }, header: idempotencyKey() },
          body: {
            cancellationFarePaise: input.cancellationFarePaise,
            ...(input.note ? { note: input.note } : {}),
          },
        }),
      ),
    [keys.trips],
  );
  const reject = useApiMutation(
    (note: string) =>
      call(
        api.POST('/cancellation-requests/{id}/reject', {
          params: { path: { id: request?.id ?? '' }, header: idempotencyKey() },
          body: { note },
        }),
      ),
    [keys.trips],
  );
  if (!request) return null;
  const pending = request.status === 'pending';
  const tone: Tone = pending ? 'warning' : request.status === 'approved' ? 'danger' : 'neutral';
  const farePaise = rupeesToPaise(fare);

  return (
    <Card
      title={t('trips.cancellation.title')}
      actions={<Badge tone={tone}>{t(`enums.cancellationStatus.${request.status}`)}</Badge>}
      className={pending ? 'border-amber-300' : undefined}
    >
      <div className="grid gap-4 sm:grid-cols-[1fr_auto]">
        <div className="space-y-2 text-sm">
          <p>
            <span className="font-medium">“{request.reason}”</span>
          </p>
          <p className="text-slate-600">
            {request.endOdometer
              ? t('trips.cancellation.requestedByWithOdometer', {
                  role: roleName(request.requestedRole),
                  when: fmtDateTime(request.createdAt),
                  km: fmtKm(request.endOdometer.typedKm),
                })
              : t('trips.cancellation.requestedBy', {
                  role: roleName(request.requestedRole),
                  when: fmtDateTime(request.createdAt),
                })}
          </p>
          {request.decisionNote && (
            <p className="text-slate-600">
              {t('trips.cancellation.decisionNote', { note: request.decisionNote })}
            </p>
          )}
          {pending && (
            <div className="flex flex-wrap gap-2 pt-2">
              <Button
                onClick={() => {
                  setDialog('approve');
                }}
              >
                {t('trips.cancellation.approve')}
              </Button>
              <Button
                variant="secondary"
                onClick={() => {
                  setDialog('reject');
                }}
              >
                {t('trips.cancellation.reject')}
              </Button>
            </div>
          )}
        </div>
        {request.endOdometer && (
          <Photo
            mediaId={request.endOdometer.mediaId}
            alt={t('trips.cancellation.odometerPhoto')}
          />
        )}
      </div>
      {dialog === 'approve' && (
        <Modal
          open
          onClose={() => {
            setDialog(null);
          }}
          title={t('trips.cancellation.approveTitle')}
          footer={
            <>
              <Button
                variant="secondary"
                onClick={() => {
                  setDialog(null);
                }}
              >
                {t('trips.back')}
              </Button>
              <Button
                busy={approve.isPending}
                disabled={farePaise === null}
                onClick={() => {
                  approve.mutate(
                    { cancellationFarePaise: farePaise ?? 0, note: '' },
                    {
                      onSuccess: () => {
                        setDialog(null);
                        void invalidate();
                      },
                    },
                  );
                }}
              >
                {t('trips.cancellation.approveButton')}
              </Button>
            </>
          }
        >
          <div className="space-y-4">
            <p className="text-sm text-slate-600">{t('trips.cancellation.approveHint')}</p>
            <Field label={t('trips.cancellation.fare')} hint={t('trips.cancellation.fareHint')}>
              {(props) => (
                <Input
                  {...props}
                  inputMode="decimal"
                  value={fare}
                  onChange={(e) => {
                    setFare(e.target.value);
                  }}
                />
              )}
            </Field>
            <InlineError error={approve.error} />
          </div>
        </Modal>
      )}
      {dialog === 'reject' && (
        <ReasonModal
          title={t('trips.cancellation.rejectTitle')}
          label={t('trips.cancellation.rejectNote')}
          confirm={t('trips.cancellation.rejectConfirm')}
          busy={reject.isPending}
          error={reject.error}
          onClose={() => {
            setDialog(null);
          }}
          onConfirm={(note) => {
            reject.mutate(note, {
              onSuccess: () => {
                setDialog(null);
                void invalidate();
              },
            });
          }}
        />
      )}
    </Card>
  );
}

function OdometerCell({ label, reading }: { label: string; reading: OdometerReading | null }) {
  const { t } = useTranslation();
  if (!reading) {
    return (
      <div>
        <p className="text-sm font-medium">{label}</p>
        <p className="text-sm text-slate-500">{t('trips.odometer.notRecorded')}</p>
      </div>
    );
  }
  const mismatch = reading.ocrKm !== null && Math.abs(reading.ocrKm - reading.typedKm) > 1;
  return (
    <div className="space-y-2">
      <p className="text-sm font-medium">{label}</p>
      <Photo mediaId={reading.mediaId} alt={t('trips.odometer.photoAlt', { label })} />
      <dl className="grid grid-cols-2 gap-2">
        <Stat label={t('trips.odometer.typed')} value={fmtKm(reading.typedKm)} />
        <Stat
          label={t('trips.odometer.readFromPhoto')}
          value={
            reading.ocrKm === null ? (
              '—'
            ) : (
              <span className={mismatch ? 'text-amber-700' : undefined}>
                {fmtKm(reading.ocrKm)}
              </span>
            )
          }
          hint={mismatch ? t('trips.odometer.differs') : undefined}
        />
      </dl>
      <p className="text-xs text-slate-500">
        {t('trips.odometer.captured', { when: fmtDateTime(reading.capturedAt) })}
      </p>
    </div>
  );
}

const VERDICT = {
  ok: { tone: 'success', label: 'trips.verdict.ok', text: 'trips.verdict.okText' },
  flagged: { tone: 'danger', label: 'trips.verdict.flagged', text: 'trips.verdict.flaggedText' },
  inconclusive: {
    tone: 'neutral',
    label: 'trips.verdict.inconclusive',
    text: 'trips.verdict.inconclusiveText',
  },
} as const satisfies Record<DistanceCheck['result'], { tone: Tone; label: string; text: string }>;

function RouteCard({ trip }: { trip: Trip }) {
  const { t } = useTranslation();
  const started = trip.startedAt !== null;
  const closed = trip.endedAt !== null || (trip.cancelledAt !== null && started);
  const route = useTripRoute(trip.id, started);
  const check = useDistanceCheck(trip.id, closed);
  const alerts = useAlerts({ tripId: trip.id, kind: 'odo_gps_mismatch', limit: 5 });
  const points = useMemo(
    () => route.data?.points.map((p) => ({ lat: p.lat, lng: p.lng })) ?? [],
    [route.data],
  );
  const from = trip.from.point ?? null;
  const to = trip.to?.point ?? null;

  return (
    <Card title={t('trips.route.title')}>
      {!started ? (
        <EmptyState title={t('trips.route.beforeStart')} />
      ) : (
        <div className="space-y-4">
          <QueryState query={route}>
            {() => <RouteMap points={points} from={from} to={to} />}
          </QueryState>
          {route.data && (
            <p className="text-xs text-slate-500">
              {t('trips.route.pointsShown', { count: route.data.points.length })}
              {route.data.dropped.inaccurate +
                route.data.dropped.mock +
                route.data.dropped.impossibleSpeed >
                0 &&
                t('trips.route.removed', {
                  inaccurate: fmtNumber(route.data.dropped.inaccurate),
                  mock: fmtNumber(route.data.dropped.mock),
                  impossible: fmtNumber(route.data.dropped.impossibleSpeed),
                })}
            </p>
          )}
          {closed && check.data && (
            <div className="rounded-md border border-slate-200 p-3">
              <div className="mb-2 flex flex-wrap items-center gap-2">
                <Badge tone={VERDICT[check.data.result].tone}>
                  {t(VERDICT[check.data.result].label)}
                </Badge>
                <span className="text-xs text-slate-500">
                  {t('trips.route.checked', { when: fmtDateTime(check.data.computedAt) })}
                </span>
              </div>
              <dl className="mb-2 grid grid-cols-2 gap-3 sm:grid-cols-4">
                <Stat label={t('trips.route.odometer')} value={fmtKm(check.data.odometerKm)} />
                <Stat
                  label={t('trips.route.gps')}
                  value={check.data.gpsKm === null ? '—' : fmtKm(check.data.gpsKm)}
                />
                <Stat
                  label={t('trips.route.coverage')}
                  value={
                    check.data.coverageRatio === null
                      ? '—'
                      : t('units.percent', {
                          value: fmtNumber(Math.round(check.data.coverageRatio * 100)),
                        })
                  }
                />
                <Stat
                  label={t('trips.route.longestGap')}
                  value={
                    check.data.maxGapSeconds === null
                      ? '—'
                      : t('trips.route.minutes', {
                          count: Math.round(check.data.maxGapSeconds / 60),
                        })
                  }
                />
              </dl>
              <p className="text-sm text-slate-600">
                {alerts.data?.[0]
                  ? alertText(alerts.data[0]).explanation
                  : t(VERDICT[check.data.result].text)}
              </p>
            </div>
          )}
          {closed && check.isSuccess && check.data === null && (
            <p className="text-sm text-slate-500">{t('trips.route.checkPending')}</p>
          )}
        </div>
      )}
    </Card>
  );
}

const CHARGE_KINDS = [
  'toll',
  'parking',
  'state_tax',
  'driver_allowance',
  'night_charge',
  'extra_km',
  'other',
] as const;

function ChargesCard({ trip }: { trip: Trip }) {
  const { t } = useTranslation();
  const roleName = useRoleName();
  const invalidate = useTripInvalidation(trip.id);
  const [adding, setAdding] = useState(false);
  const [kind, setKind] = useState<(typeof CHARGE_KINDS)[number]>('toll');
  const [amount, setAmount] = useState('');
  const [paidByDriver, setPaidByDriver] = useState(true);
  const [note, setNote] = useState('');
  const add = useApiMutation(
    (amountPaise: number) =>
      call(
        api.POST('/trips/{id}/charges', {
          params: { path: { id: trip.id } },
          body: {
            id: crypto.randomUUID(),
            kind,
            amountPaise,
            paidByDriver: chargePaidByDriver({ kind, paidByDriver }),
            ...(note.trim() ? { note: note.trim() } : {}),
          },
        }),
      ),
    [],
  );
  const voidCharge = useApiMutation(
    (chargeId: string) =>
      call(
        api.POST('/trips/{id}/charges/{chargeId}/void', {
          params: { path: { id: trip.id, chargeId } },
        }),
      ),
    [],
  );
  const editable = trip.status !== 'settled' && !(trip.status === 'cancelled' && !trip.startedAt);
  const amountPaise = rupeesToPaise(amount);

  function submit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    if (amountPaise === null) return;
    add.mutate(amountPaise, {
      onSuccess: () => {
        setAdding(false);
        setAmount('');
        setNote('');
        void invalidate();
      },
    });
  }

  return (
    <Card
      title={t('trips.charges.title')}
      actions={
        editable && (
          <Button
            size="sm"
            variant="secondary"
            onClick={() => {
              setAdding(true);
            }}
          >
            {t('trips.charges.add')}
          </Button>
        )
      }
    >
      {trip.charges.length === 0 ? (
        <p className="text-sm text-slate-500">{t('trips.charges.none')}</p>
      ) : (
        <Table>
          <tbody>
            {trip.charges.map((c) => (
              <tr key={c.id} className={c.voidedAt ? 'text-slate-400 line-through' : undefined}>
                <Td>
                  {t(`enums.chargeKind.${c.kind}`)}
                  {c.note && (
                    <span className="block text-xs text-slate-500 no-underline">{c.note}</span>
                  )}
                </Td>
                <Td>
                  <span className="text-xs text-slate-500">
                    {t('trips.charges.byRole', {
                      type: isExtraFareCharge(c.kind)
                        ? t('trips.charges.extraFare')
                        : c.paidByDriver
                          ? t('trips.charges.driverPaid')
                          : t('trips.charges.billedOnly'),
                      role: roleName(c.enteredRole),
                    })}
                  </span>
                </Td>
                <Td align="right">{fmtInr(c.amountPaise)}</Td>
                <Td className="w-16 text-right">
                  {editable && !c.voidedAt && (
                    <Button
                      variant="ghost"
                      size="sm"
                      busy={voidCharge.isPending && voidCharge.variables === c.id}
                      onClick={() => {
                        voidCharge.mutate(c.id, { onSuccess: () => void invalidate() });
                      }}
                    >
                      {t('trips.charges.void')}
                    </Button>
                  )}
                </Td>
              </tr>
            ))}
          </tbody>
        </Table>
      )}
      <InlineError error={voidCharge.error} />
      {adding && (
        <Modal
          open
          onClose={() => {
            setAdding(false);
          }}
          title={t('trips.charges.addTitle')}
        >
          <form onSubmit={submit} className="space-y-4">
            <Field label={t('trips.charges.kind')}>
              {(props) => (
                <Select
                  {...props}
                  value={kind}
                  onChange={(e) => {
                    setKind(e.target.value as typeof kind);
                  }}
                >
                  {CHARGE_KINDS.map((k) => (
                    <option key={k} value={k}>
                      {t(`enums.chargeKind.${k}`)}
                    </option>
                  ))}
                </Select>
              )}
            </Field>
            <Field label={t('trips.charges.amount')}>
              {(props) => (
                <Input
                  {...props}
                  inputMode="decimal"
                  required
                  value={amount}
                  onChange={(e) => {
                    setAmount(e.target.value);
                  }}
                />
              )}
            </Field>
            {isExtraFareCharge(kind) ? (
              <p className="rounded-md bg-brand-50 px-3 py-2 text-sm text-brand-800">
                {t('trips.charges.extraFareHint')}
              </p>
            ) : (
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={paidByDriver}
                  onChange={(e) => {
                    setPaidByDriver(e.target.checked);
                  }}
                />
                {t('trips.charges.paidByDriver')}
              </label>
            )}
            <Field label={t('trips.charges.note')}>
              {(props) => (
                <Input
                  {...props}
                  value={note}
                  onChange={(e) => {
                    setNote(e.target.value);
                  }}
                />
              )}
            </Field>
            <InlineError error={add.error} />
            <div className="flex justify-end gap-2">
              <Button
                variant="secondary"
                onClick={() => {
                  setAdding(false);
                }}
              >
                {t('common.cancel')}
              </Button>
              <Button type="submit" busy={add.isPending} disabled={amountPaise === null}>
                {t('trips.charges.add')}
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </Card>
  );
}

function CollectionsCard({ trip }: { trip: Trip }) {
  const { t } = useTranslation();
  const invalidate = useTripInvalidation(trip.id);
  const [adding, setAdding] = useState(false);
  const [method, setMethod] = useState<'cash' | 'upi' | 'card'>('cash');
  const [amount, setAmount] = useState('');
  const [reference, setReference] = useState('');
  const add = useApiMutation(
    (amountPaise: number) =>
      call(
        api.POST('/trips/{id}/collections', {
          params: { path: { id: trip.id } },
          body: {
            id: crypto.randomUUID(),
            method,
            amountPaise,
            ...(reference.trim() ? { reference: reference.trim() } : {}),
          },
        }),
      ),
    [],
  );
  const total = trip.collections.reduce((sum, c) => sum + c.amountPaise, 0);
  const amountPaise = rupeesToPaise(amount);

  return (
    <Card
      title={t('trips.payments.title')}
      actions={
        trip.startedAt && (
          <Button
            size="sm"
            variant="secondary"
            onClick={() => {
              setAdding(true);
            }}
          >
            {t('trips.payments.record')}
          </Button>
        )
      }
    >
      {trip.collections.length === 0 ? (
        <p className="text-sm text-slate-500">{t('trips.payments.none')}</p>
      ) : (
        <Table>
          <tbody>
            {trip.collections.map((c) => (
              <tr key={c.id}>
                <Td>{t(`enums.collectionMethod.${c.method}`)}</Td>
                <Td className="text-xs text-slate-500">
                  {fmtDateTime(c.collectedAt)}
                  {c.reference ? ` · ${c.reference}` : ''}
                </Td>
                <Td align="right">{fmtInr(c.amountPaise)}</Td>
              </tr>
            ))}
            <tr>
              <Td className="font-medium">{t('trips.payments.total')}</Td>
              <Td />
              <Td align="right" className="font-semibold">
                {fmtInr(total)}
              </Td>
            </tr>
          </tbody>
        </Table>
      )}
      {adding && (
        <Modal
          open
          onClose={() => {
            setAdding(false);
          }}
          title={t('trips.payments.recordTitle')}
        >
          <form
            className="space-y-4"
            onSubmit={(e) => {
              e.preventDefault();
              if (amountPaise === null) return;
              add.mutate(amountPaise, {
                onSuccess: () => {
                  setAdding(false);
                  setAmount('');
                  setReference('');
                  void invalidate();
                },
              });
            }}
          >
            <Field label={t('trips.payments.method')}>
              {(props) => (
                <Select
                  {...props}
                  value={method}
                  onChange={(e) => {
                    setMethod(e.target.value as typeof method);
                  }}
                >
                  <option value="cash">{t('trips.payments.cash')}</option>
                  <option value="upi">{t('trips.payments.upi')}</option>
                  <option value="card">{t('trips.payments.card')}</option>
                </Select>
              )}
            </Field>
            <Field label={t('trips.payments.amount')}>
              {(props) => (
                <Input
                  {...props}
                  inputMode="decimal"
                  required
                  value={amount}
                  onChange={(e) => {
                    setAmount(e.target.value);
                  }}
                />
              )}
            </Field>
            <Field label={t('trips.payments.reference')} hint={t('trips.payments.referenceHint')}>
              {(props) => (
                <Input
                  {...props}
                  value={reference}
                  onChange={(e) => {
                    setReference(e.target.value);
                  }}
                />
              )}
            </Field>
            <InlineError error={add.error} />
            <div className="flex justify-end gap-2">
              <Button
                variant="secondary"
                onClick={() => {
                  setAdding(false);
                }}
              >
                {t('common.cancel')}
              </Button>
              <Button type="submit" busy={add.isPending} disabled={amountPaise === null}>
                {t('trips.payments.submit')}
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </Card>
  );
}

function Timeline({ events }: { events: TripEvent[] }) {
  const { t } = useTranslation();
  const roleName = useRoleName();
  return (
    <ol className="space-y-3">
      {events.map((e) => {
        const skewMinutes = Math.round(
          (new Date(e.recordedAt).getTime() - new Date(e.occurredAt).getTime()) / 60_000,
        );
        const name = e.eventType.replace('trip.', '');
        return (
          <li key={e.id} className="flex gap-3 text-sm">
            <span className="mt-1.5 size-2 shrink-0 rounded-full bg-brand-500" aria-hidden />
            <div>
              <p className="font-medium text-slate-900">
                {isEventName(name) ? t(`enums.tripEvent.${name}`) : name}
                <span className="font-normal text-slate-500">
                  {e.actorRole
                    ? t('trips.timeline.byRole', { role: roleName(e.actorRole) })
                    : t('trips.timeline.system')}
                </span>
              </p>
              <p className="text-xs text-slate-500">
                {t('trips.timeline.onDevice', { when: fmtDateTime(e.occurredAt) })}
                {skewMinutes >= 2
                  ? t('trips.timeline.synced', {
                      when: fmtDateTime(e.recordedAt),
                      minutes: fmtNumber(skewMinutes),
                    })
                  : ''}
              </p>
            </div>
          </li>
        );
      })}
    </ol>
  );
}

export function TripDetailPage() {
  const { t } = useTranslation();
  const { id = '' } = useParams();
  const trip = useTrip(id);
  const events = useTripEvents(id);

  return (
    <QueryState query={trip}>
      {(trip) => (
        <>
          <PageHeader
            title={
              trip.to
                ? t('common.route', { from: trip.from.text, to: trip.to.text })
                : t('trips.detail.localTitle', { from: trip.from.text })
            }
            description={
              <span className="flex flex-wrap items-center gap-2">
                <TripStatusBadge status={trip.status} />
                <span>
                  {t('trips.detail.schedule', {
                    type: t(`enums.tripType.${trip.tripType}`),
                    start: fmtDateTime(trip.scheduledStartAt),
                    end: fmtDateTime(trip.scheduledEndAt),
                  })}
                </span>
              </span>
            }
            actions={<Actions trip={trip} />}
          />
          <div className="grid gap-4 lg:grid-cols-3">
            <div className="space-y-4 lg:col-span-2">
              <CancellationCard trip={trip} />
              <Card title={t('trips.detail.trip')}>
                <dl className="grid grid-cols-2 gap-4 sm:grid-cols-3">
                  <Stat
                    label={t('trips.detail.customer')}
                    value={trip.customer?.name ?? '—'}
                    hint={trip.customer?.phone ? fmtPhone(trip.customer.phone) : undefined}
                  />
                  <Stat
                    label={t('trips.detail.vehicle')}
                    value={
                      trip.vehicle ? (
                        <Link
                          className="text-brand-700 hover:underline"
                          to={`/vehicles/${trip.vehicle.id}`}
                        >
                          {fmtRegistration(trip.vehicle.registrationNo)}
                        </Link>
                      ) : (
                        t('common.unassigned')
                      )
                    }
                    hint={trip.vehicle?.model}
                  />
                  <Stat
                    label={t('trips.detail.driver')}
                    value={trip.driver?.name ?? t('common.unassigned')}
                  />
                  <Stat label={t('trips.detail.quotedFare')} value={fmtInr(trip.quotedFarePaise)} />
                  <Stat
                    label={t('trips.detail.includedKm')}
                    value={
                      trip.includedKm === null ? t('trips.detail.notSet') : fmtKm(trip.includedKm)
                    }
                    hint={(() => {
                      const driven =
                        trip.startOdometer && trip.endOdometer
                          ? trip.endOdometer.typedKm - trip.startOdometer.typedKm
                          : null;
                      if (trip.includedKm === null || driven === null) return undefined;
                      return driven > trip.includedKm
                        ? t('trips.detail.kmOver', {
                            over: fmtKm(driven - trip.includedKm),
                            driven: fmtKm(driven),
                          })
                        : t('trips.detail.driven', { driven: fmtKm(driven) });
                    })()}
                  />
                  {trip.cancellationFarePaise !== null && (
                    <Stat
                      label={t('trips.detail.cancellationFare')}
                      value={fmtInr(trip.cancellationFarePaise)}
                    />
                  )}
                  <Stat label={t('trips.detail.started')} value={fmtDateTime(trip.startedAt)} />
                  <Stat label={t('trips.detail.ended')} value={fmtDateTime(trip.endedAt)} />
                  {trip.cancelledAt && (
                    <Stat
                      label={t('trips.detail.cancelled')}
                      value={fmtDateTime(trip.cancelledAt)}
                      hint={trip.cancelReason ?? undefined}
                    />
                  )}
                  {trip.startOdometer && trip.endOdometer && (
                    <Stat
                      label={t('trips.detail.odometerDistance')}
                      value={fmtKm(trip.endOdometer.typedKm - trip.startOdometer.typedKm)}
                    />
                  )}
                </dl>
              </Card>
              <Card title={t('trips.odometer.evidence')}>
                <div className="grid gap-6 sm:grid-cols-2">
                  <OdometerCell label={t('trips.odometer.start')} reading={trip.startOdometer} />
                  <OdometerCell label={t('trips.odometer.end')} reading={trip.endOdometer} />
                </div>
              </Card>
              <RouteCard trip={trip} />
            </div>
            <div className="space-y-4">
              <CollectionsCard trip={trip} />
              <ChargesCard trip={trip} />
              <Card title={t('trips.timeline.title')}>
                <QueryState query={events}>
                  {(list) =>
                    list.length ? (
                      <Timeline events={list} />
                    ) : (
                      <EmptyState title={t('trips.timeline.none')} />
                    )
                  }
                </QueryState>
              </Card>
            </div>
          </div>
        </>
      )}
    </QueryState>
  );
}
