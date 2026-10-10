import { useQueryClient } from '@tanstack/react-query';
import { chargePaidByDriver, isExtraFareCharge } from '@taxcy/domain';
import { useMemo, useState, type SubmitEvent } from 'react';
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
import { api, call, idempotencyKey } from '../lib/api.js';
import type { DistanceCheck, Trip, TripEvent } from '../lib/api-types.js';
import {
  fmtDateTime,
  fmtInr,
  fmtKm,
  fmtPhone,
  fmtRegistration,
  humanize,
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
      title={trip.vehicle ? 'Reassign trip' : 'Assign trip'}
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button
            busy={assign.isPending}
            disabled={!vehicleId || !driverId}
            onClick={() => {
              assign.mutate(undefined, { onSuccess: onClose });
            }}
          >
            {trip.vehicle ? 'Reassign' : 'Assign'}
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <Field label="Vehicle">
          {(props) => <VehicleSelect {...props} value={vehicleId} onChange={setVehicleId} />}
        </Field>
        <Field label="Driver">
          {(props) => <DriverSelect {...props} value={driverId} onChange={setDriverId} />}
        </Field>
        <p className="text-xs text-slate-500">
          A vehicle or driver already booked for an overlapping time can’t be assigned.
        </p>
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
  const [text, setText] = useState('');
  return (
    <Modal
      open
      onClose={onClose}
      title={title}
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>
            Back
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
          {can('assign') ? 'Assign' : 'Reassign'}
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
          Unassign
        </Button>
      )}
      {can('cancel') && (
        <Button
          variant="secondary"
          onClick={() => {
            setDialog('cancel');
          }}
        >
          Cancel trip
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
          title="Cancel this trip"
          label="Reason"
          confirm="Cancel trip"
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
      title="Cancellation request"
      actions={<Badge tone={tone}>{humanize(request.status)}</Badge>}
      className={pending ? 'border-amber-300' : undefined}
    >
      <div className="grid gap-4 sm:grid-cols-[1fr_auto]">
        <div className="space-y-2 text-sm">
          <p>
            <span className="font-medium">“{request.reason}”</span>
          </p>
          <p className="text-slate-600">
            Requested by the {request.requestedRole} on {fmtDateTime(request.createdAt)}
            {request.endOdometer ? ` · odometer ${fmtKm(request.endOdometer.typedKm)}` : ''}
          </p>
          {request.decisionNote && (
            <p className="text-slate-600">Decision note: {request.decisionNote}</p>
          )}
          {pending && (
            <div className="flex flex-wrap gap-2 pt-2">
              <Button
                onClick={() => {
                  setDialog('approve');
                }}
              >
                Approve cancellation
              </Button>
              <Button
                variant="secondary"
                onClick={() => {
                  setDialog('reject');
                }}
              >
                Reject
              </Button>
            </div>
          )}
        </div>
        {request.endOdometer && (
          <Photo mediaId={request.endOdometer.mediaId} alt="Odometer at cancellation" />
        )}
      </div>
      {dialog === 'approve' && (
        <Modal
          open
          onClose={() => {
            setDialog(null);
          }}
          title="Approve cancellation"
          footer={
            <>
              <Button
                variant="secondary"
                onClick={() => {
                  setDialog(null);
                }}
              >
                Back
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
                Approve
              </Button>
            </>
          }
        >
          <div className="space-y-4">
            <p className="text-sm text-slate-600">
              The trip becomes cancelled. You can charge for the distance already driven.
            </p>
            <Field label="Cancellation fare (₹)" hint="0 for no charge.">
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
          title="Reject cancellation"
          label="Note for the driver"
          confirm="Reject — the trip continues"
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
  if (!reading) {
    return (
      <div>
        <p className="text-sm font-medium">{label}</p>
        <p className="text-sm text-slate-500">Not recorded yet</p>
      </div>
    );
  }
  const mismatch = reading.ocrKm !== null && Math.abs(reading.ocrKm - reading.typedKm) > 1;
  return (
    <div className="space-y-2">
      <p className="text-sm font-medium">{label}</p>
      <Photo mediaId={reading.mediaId} alt={`${label} odometer photo`} />
      <dl className="grid grid-cols-2 gap-2">
        <Stat label="Typed" value={fmtKm(reading.typedKm)} />
        <Stat
          label="Read from photo"
          value={
            reading.ocrKm === null ? (
              '—'
            ) : (
              <span className={mismatch ? 'text-amber-700' : undefined}>
                {fmtKm(reading.ocrKm)}
              </span>
            )
          }
          hint={mismatch ? 'Differs: sent to the review queue' : undefined}
        />
      </dl>
      <p className="text-xs text-slate-500">Captured {fmtDateTime(reading.capturedAt)}</p>
    </div>
  );
}

const VERDICT: Record<DistanceCheck['result'], { tone: Tone; label: string; text: string }> = {
  ok: {
    tone: 'success',
    label: 'Odometer matches GPS',
    text: 'The odometer distance is within the allowed difference from the GPS route.',
  },
  flagged: {
    tone: 'danger',
    label: 'Odometer higher than GPS',
    text: 'The odometer distance is well above the GPS route. See the alert for details.',
  },
  inconclusive: {
    tone: 'neutral',
    label: 'Not enough GPS to judge',
    text: 'The phone recorded too little of the trip (often battery-saving settings). No alert is raised in this case.',
  },
};

function RouteCard({ trip }: { trip: Trip }) {
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
    <Card title="Route">
      {!started ? (
        <EmptyState title="The route appears once the trip starts" />
      ) : (
        <div className="space-y-4">
          <QueryState query={route}>
            {() => <RouteMap points={points} from={from} to={to} />}
          </QueryState>
          {route.data && (
            <p className="text-xs text-slate-500">
              {route.data.points.length} GPS points shown
              {route.data.dropped.inaccurate +
                route.data.dropped.mock +
                route.data.dropped.impossibleSpeed >
                0 &&
                ` · removed ${String(route.data.dropped.inaccurate)} inaccurate, ${String(route.data.dropped.mock)} mock and ${String(route.data.dropped.impossibleSpeed)} impossible points`}
            </p>
          )}
          {closed && check.data && (
            <div className="rounded-md border border-slate-200 p-3">
              <div className="mb-2 flex flex-wrap items-center gap-2">
                <Badge tone={VERDICT[check.data.result].tone}>
                  {VERDICT[check.data.result].label}
                </Badge>
                <span className="text-xs text-slate-500">
                  checked {fmtDateTime(check.data.computedAt)}
                </span>
              </div>
              <dl className="mb-2 grid grid-cols-2 gap-3 sm:grid-cols-4">
                <Stat label="Odometer" value={fmtKm(check.data.odometerKm)} />
                <Stat
                  label="GPS"
                  value={check.data.gpsKm === null ? '—' : fmtKm(check.data.gpsKm)}
                />
                <Stat
                  label="GPS coverage"
                  value={
                    check.data.coverageRatio === null
                      ? '—'
                      : `${String(Math.round(check.data.coverageRatio * 100))}%`
                  }
                />
                <Stat
                  label="Longest gap"
                  value={
                    check.data.maxGapSeconds === null
                      ? '—'
                      : `${String(Math.round(check.data.maxGapSeconds / 60))} min`
                  }
                />
              </dl>
              <p className="text-sm text-slate-600">
                {alerts.data?.[0]?.explanation ?? VERDICT[check.data.result].text}
              </p>
            </div>
          )}
          {closed && check.isSuccess && check.data === null && (
            <p className="text-sm text-slate-500">
              The distance check runs a few seconds after the trip ends.
            </p>
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
      title="Charges"
      actions={
        editable && (
          <Button
            size="sm"
            variant="secondary"
            onClick={() => {
              setAdding(true);
            }}
          >
            Add charge
          </Button>
        )
      }
    >
      {trip.charges.length === 0 ? (
        <p className="text-sm text-slate-500">No tolls, parking or other charges.</p>
      ) : (
        <Table>
          <tbody>
            {trip.charges.map((c) => (
              <tr key={c.id} className={c.voidedAt ? 'text-slate-400 line-through' : undefined}>
                <Td>
                  {humanize(c.kind)}
                  {c.note && (
                    <span className="block text-xs text-slate-500 no-underline">{c.note}</span>
                  )}
                </Td>
                <Td>
                  <span className="text-xs text-slate-500">
                    {isExtraFareCharge(c.kind)
                      ? 'Extra fare'
                      : c.paidByDriver
                        ? 'Driver paid'
                        : 'Billed only'}{' '}
                    · by {c.enteredRole}
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
                      Void
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
          title="Add a charge"
        >
          <form onSubmit={submit} className="space-y-4">
            <Field label="Kind">
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
                      {humanize(k)}
                    </option>
                  ))}
                </Select>
              )}
            </Field>
            <Field label="Amount (₹)">
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
                Extra fare: added to what the customer pays, on top of the quoted fare.
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
                The driver paid this out of pocket (reimbursed in settlement)
              </label>
            )}
            <Field label="Note">
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
                Cancel
              </Button>
              <Button type="submit" busy={add.isPending} disabled={amountPaise === null}>
                Add charge
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </Card>
  );
}

function CollectionsCard({ trip }: { trip: Trip }) {
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
      title="Payments collected"
      actions={
        trip.startedAt && (
          <Button
            size="sm"
            variant="secondary"
            onClick={() => {
              setAdding(true);
            }}
          >
            Record payment
          </Button>
        )
      }
    >
      {trip.collections.length === 0 ? (
        <p className="text-sm text-slate-500">Nothing recorded yet.</p>
      ) : (
        <Table>
          <tbody>
            {trip.collections.map((c) => (
              <tr key={c.id}>
                <Td>{c.method.toUpperCase()}</Td>
                <Td className="text-xs text-slate-500">
                  {fmtDateTime(c.collectedAt)}
                  {c.reference ? ` · ${c.reference}` : ''}
                </Td>
                <Td align="right">{fmtInr(c.amountPaise)}</Td>
              </tr>
            ))}
            <tr>
              <Td className="font-medium">Total</Td>
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
          title="Record a payment"
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
            <Field label="Method">
              {(props) => (
                <Select
                  {...props}
                  value={method}
                  onChange={(e) => {
                    setMethod(e.target.value as typeof method);
                  }}
                >
                  <option value="cash">Cash (driver hands it over at settlement)</option>
                  <option value="upi">UPI (comes straight to you)</option>
                  <option value="card">Card (comes straight to you)</option>
                </Select>
              )}
            </Field>
            <Field label="Amount (₹)">
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
            <Field label="Reference (optional)" hint="UPI reference or card slip number.">
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
                Cancel
              </Button>
              <Button type="submit" busy={add.isPending} disabled={amountPaise === null}>
                Record
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </Card>
  );
}

function Timeline({ events }: { events: TripEvent[] }) {
  return (
    <ol className="space-y-3">
      {events.map((e) => {
        const skewMinutes = Math.round(
          (new Date(e.recordedAt).getTime() - new Date(e.occurredAt).getTime()) / 60_000,
        );
        return (
          <li key={e.id} className="flex gap-3 text-sm">
            <span className="mt-1.5 size-2 shrink-0 rounded-full bg-brand-500" aria-hidden />
            <div>
              <p className="font-medium text-slate-900">
                {humanize(e.eventType.replace('trip.', ''))}
                {e.actorRole ? (
                  <span className="font-normal text-slate-500"> by {e.actorRole}</span>
                ) : (
                  <span className="font-normal text-slate-500"> (system)</span>
                )}
              </p>
              <p className="text-xs text-slate-500">
                {fmtDateTime(e.occurredAt)} on the device
                {skewMinutes >= 2
                  ? ` · reached the server ${fmtDateTime(e.recordedAt)} (synced ${String(skewMinutes)} min later)`
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
  const { id = '' } = useParams();
  const trip = useTrip(id);
  const events = useTripEvents(id);

  return (
    <QueryState query={trip}>
      {(t) => (
        <>
          <PageHeader
            title={t.to ? `${t.from.text} → ${t.to.text}` : `${t.from.text} (local rental)`}
            description={
              <span className="flex flex-wrap items-center gap-2">
                <TripStatusBadge status={t.status} />
                <span>
                  {humanize(t.tripType)} · {fmtDateTime(t.scheduledStartAt)} –{' '}
                  {fmtDateTime(t.scheduledEndAt)}
                </span>
              </span>
            }
            actions={<Actions trip={t} />}
          />
          <div className="grid gap-4 lg:grid-cols-3">
            <div className="space-y-4 lg:col-span-2">
              <CancellationCard trip={t} />
              <Card title="Trip">
                <dl className="grid grid-cols-2 gap-4 sm:grid-cols-3">
                  <Stat
                    label="Customer"
                    value={t.customer?.name ?? '—'}
                    hint={t.customer?.phone ? fmtPhone(t.customer.phone) : undefined}
                  />
                  <Stat
                    label="Vehicle"
                    value={
                      t.vehicle ? (
                        <Link
                          className="text-brand-700 hover:underline"
                          to={`/vehicles/${t.vehicle.id}`}
                        >
                          {fmtRegistration(t.vehicle.registrationNo)}
                        </Link>
                      ) : (
                        'Unassigned'
                      )
                    }
                    hint={t.vehicle?.model}
                  />
                  <Stat label="Driver" value={t.driver?.name ?? 'Unassigned'} />
                  <Stat label="Quoted fare" value={fmtInr(t.quotedFarePaise)} />
                  <Stat
                    label="Included km"
                    value={t.includedKm === null ? 'Not set' : `${String(t.includedKm)} km`}
                    hint={(() => {
                      const driven =
                        t.startOdometer && t.endOdometer
                          ? t.endOdometer.typedKm - t.startOdometer.typedKm
                          : null;
                      if (t.includedKm === null || driven === null) return undefined;
                      return driven > t.includedKm
                        ? `${String(driven - t.includedKm)} km over (driven ${String(driven)} km)`
                        : `Driven ${String(driven)} km`;
                    })()}
                  />
                  {t.cancellationFarePaise !== null && (
                    <Stat label="Cancellation fare" value={fmtInr(t.cancellationFarePaise)} />
                  )}
                  <Stat label="Started" value={fmtDateTime(t.startedAt)} />
                  <Stat label="Ended" value={fmtDateTime(t.endedAt)} />
                  {t.cancelledAt && (
                    <Stat
                      label="Cancelled"
                      value={fmtDateTime(t.cancelledAt)}
                      hint={t.cancelReason ?? undefined}
                    />
                  )}
                  {t.startOdometer && t.endOdometer && (
                    <Stat
                      label="Odometer distance"
                      value={fmtKm(t.endOdometer.typedKm - t.startOdometer.typedKm)}
                    />
                  )}
                </dl>
              </Card>
              <Card title="Odometer evidence">
                <div className="grid gap-6 sm:grid-cols-2">
                  <OdometerCell label="Start" reading={t.startOdometer} />
                  <OdometerCell label="End" reading={t.endOdometer} />
                </div>
              </Card>
              <RouteCard trip={t} />
            </div>
            <div className="space-y-4">
              <CollectionsCard trip={t} />
              <ChargesCard trip={t} />
              <Card title="Timeline">
                <QueryState query={events}>
                  {(list) =>
                    list.length ? <Timeline events={list} /> : <EmptyState title="No events" />
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
