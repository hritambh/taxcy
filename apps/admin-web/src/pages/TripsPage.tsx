import { Plus } from 'lucide-react';
import { useState, type SubmitEvent } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router';
import { PointPicker, type LatLng } from '../components/maps.js';
import { DriverSelect, VehicleSelect } from '../components/shared.js';
import { TripStatusBadge } from '../components/status.js';
import {
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
  Table,
  Td,
  Th,
} from '../components/ui.js';
import { api, call } from '../lib/api.js';
import type { CreateTripBody, Trip, TripStatus } from '../lib/api-types.js';
import {
  fmtDateTime,
  fmtInr,
  fmtRegistration,
  istDayRange,
  istLocalToIso,
  istToday,
  rupeesToPaise,
} from '../lib/format.js';
import { keys, useTrips, type TripFilter } from '../lib/queries.js';
import { useApiMutation } from '../lib/mutations.js';

const STATUSES: TripStatus[] = ['created', 'assigned', 'started', 'ended', 'settled', 'cancelled'];
const TRIP_TYPES: { id: Trip['tripType']; label: string }[] = [
  { id: 'one_way', label: 'One way' },
  { id: 'round_trip', label: 'Round trip' },
  { id: 'local_rental', label: 'Local rental' },
];

function CreateTripModal({ onClose }: { onClose: () => void }) {
  const navigate = useNavigate();
  const [tripType, setTripType] = useState<Trip['tripType']>('one_way');
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [fromText, setFromText] = useState('');
  const [fromPoint, setFromPoint] = useState<LatLng | null>(null);
  const [toText, setToText] = useState('');
  const [toPoint, setToPoint] = useState<LatLng | null>(null);
  const [start, setStart] = useState('');
  const [end, setEnd] = useState('');
  const [fare, setFare] = useState('');
  const [vehicleId, setVehicleId] = useState('');
  const [driverId, setDriverId] = useState('');
  const [problem, setProblem] = useState<string | null>(null);

  const create = useApiMutation(
    (body: CreateTripBody) => call(api.POST('/trips', { body })),
    [keys.trips],
  );

  function submit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    const quotedFarePaise = rupeesToPaise(fare);
    const problemText =
      quotedFarePaise === null
        ? 'Enter the fare in rupees, e.g. 3500'
        : !start || !end || end <= start
          ? 'The end time must be after the start time'
          : Boolean(vehicleId) !== Boolean(driverId)
            ? 'Pick both a vehicle and a driver, or neither'
            : null;
    if (problemText !== null || quotedFarePaise === null) {
      setProblem(problemText);
      return;
    }
    const digits = customerPhone.replace(/\D/g, '').slice(-10);
    setProblem(null);
    create.mutate(
      {
        tripType,
        from: { text: fromText.trim(), point: fromPoint },
        ...(tripType !== 'local_rental' ? { to: { text: toText.trim(), point: toPoint } } : {}),
        scheduledStartAt: istLocalToIso(start),
        scheduledEndAt: istLocalToIso(end),
        quotedFarePaise,
        ...(customerName.trim()
          ? {
              customer: {
                name: customerName.trim(),
                ...(digits.length === 10 ? { phone: `+91${digits}` } : {}),
              },
            }
          : {}),
        ...(vehicleId && driverId ? { vehicleId, driverId } : {}),
      },
      {
        onSuccess: (trip) => {
          onClose();
          void navigate(`/trips/${trip.id}`);
        },
      },
    );
  }

  return (
    <Modal open wide onClose={onClose} title="New trip">
      <form onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
        <Field label="Trip type">
          {(props) => (
            <Select
              {...props}
              value={tripType}
              onChange={(e) => {
                setTripType(e.target.value as Trip['tripType']);
              }}
            >
              {TRIP_TYPES.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.label}
                </option>
              ))}
            </Select>
          )}
        </Field>
        <Field label="Quoted fare (₹)">
          {(props) => (
            <Input
              {...props}
              required
              inputMode="decimal"
              placeholder="3500"
              value={fare}
              onChange={(e) => {
                setFare(e.target.value);
              }}
            />
          )}
        </Field>
        <Field label="Customer name">
          {(props) => (
            <Input
              {...props}
              value={customerName}
              onChange={(e) => {
                setCustomerName(e.target.value);
              }}
            />
          )}
        </Field>
        <Field label="Customer mobile">
          {(props) => (
            <Input
              {...props}
              inputMode="tel"
              value={customerPhone}
              onChange={(e) => {
                setCustomerPhone(e.target.value);
              }}
            />
          )}
        </Field>
        <Field label="Pickup">
          {(props) => (
            <div className="space-y-2">
              <Input
                {...props}
                required
                placeholder="Pune Station"
                value={fromText}
                onChange={(e) => {
                  setFromText(e.target.value);
                }}
              />
              <PointPicker value={fromPoint} onChange={setFromPoint} label="Pickup" />
            </div>
          )}
        </Field>
        {tripType !== 'local_rental' ? (
          <Field label="Drop">
            {(props) => (
              <div className="space-y-2">
                <Input
                  {...props}
                  required
                  placeholder="Mumbai Airport T2"
                  value={toText}
                  onChange={(e) => {
                    setToText(e.target.value);
                  }}
                />
                <PointPicker value={toPoint} onChange={setToPoint} label="Drop" />
              </div>
            )}
          </Field>
        ) : (
          <div />
        )}
        <Field label="Starts (IST)">
          {(props) => (
            <Input
              {...props}
              type="datetime-local"
              required
              value={start}
              onChange={(e) => {
                setStart(e.target.value);
              }}
            />
          )}
        </Field>
        <Field label="Ends (IST)">
          {(props) => (
            <Input
              {...props}
              type="datetime-local"
              required
              value={end}
              onChange={(e) => {
                setEnd(e.target.value);
              }}
            />
          )}
        </Field>
        <Field label="Vehicle (optional)">
          {(props) => (
            <VehicleSelect
              {...props}
              value={vehicleId}
              onChange={setVehicleId}
              placeholder="Assign later"
            />
          )}
        </Field>
        <Field label="Driver (optional)">
          {(props) => (
            <DriverSelect
              {...props}
              value={driverId}
              onChange={setDriverId}
              placeholder="Assign later"
            />
          )}
        </Field>
        <div className="space-y-2 sm:col-span-2">
          {problem && <p className="text-sm text-red-600">{problem}</p>}
          <InlineError error={create.error} />
        </div>
        <div className="flex justify-end gap-2 sm:col-span-2">
          <Button variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" busy={create.isPending}>
            Create trip
          </Button>
        </div>
      </form>
    </Modal>
  );
}

export function TripsPage() {
  const [params, setParams] = useSearchParams();
  const [creating, setCreating] = useState(false);
  const status = (params.get('status') ?? '') as TripStatus | '';
  const date = params.get('date') ?? '';
  const driverId = params.get('driverId') ?? '';
  const vehicleId = params.get('vehicleId') ?? '';
  const filter: TripFilter = {
    limit: 200,
    ...(status ? { status } : {}),
    ...(driverId ? { driverId } : {}),
    ...(vehicleId ? { vehicleId } : {}),
    ...(date ? istDayRange(date) : {}),
  };
  const trips = useTrips(filter);
  const setParam = (key: string, value: string) => {
    const next = new URLSearchParams(params);
    if (value) next.set(key, value);
    else next.delete(key);
    setParams(next, { replace: true });
  };

  return (
    <>
      <PageHeader
        title="Trips"
        actions={
          <Button
            onClick={() => {
              setCreating(true);
            }}
          >
            <Plus className="size-4" aria-hidden />
            New trip
          </Button>
        }
      />
      <div className="mb-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
        <Select
          aria-label="Status"
          value={status}
          onChange={(e) => {
            setParam('status', e.target.value);
          }}
        >
          <option value="">All statuses</option>
          {STATUSES.map((s) => (
            <option key={s} value={s} className="capitalize">
              {s}
            </option>
          ))}
        </Select>
        <Input
          aria-label="Date (IST)"
          type="date"
          value={date}
          max={istToday()}
          onChange={(e) => {
            setParam('date', e.target.value);
          }}
        />
        <DriverSelect
          aria-label="Driver"
          value={driverId}
          placeholder="All drivers"
          onChange={(v) => {
            setParam('driverId', v);
          }}
        />
        <VehicleSelect
          aria-label="Vehicle"
          value={vehicleId}
          placeholder="All vehicles"
          onChange={(v) => {
            setParam('vehicleId', v);
          }}
        />
      </div>
      <Card>
        <QueryState query={trips}>
          {(list) =>
            list.length === 0 ? (
              <EmptyState title="No trips match these filters" />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <Th>Scheduled (IST)</Th>
                    <Th>Route</Th>
                    <Th>Customer</Th>
                    <Th>Vehicle · Driver</Th>
                    <Th align="right">Fare</Th>
                    <Th>Status</Th>
                  </tr>
                </thead>
                <tbody>
                  {list.map((t) => (
                    <tr key={t.id} className="hover:bg-slate-50">
                      <Td className="whitespace-nowrap">{fmtDateTime(t.scheduledStartAt)}</Td>
                      <Td>
                        <Link
                          className="font-medium text-brand-700 hover:underline"
                          to={`/trips/${t.id}`}
                        >
                          {t.from.text}
                          {t.to ? ` → ${t.to.text}` : ' (local)'}
                        </Link>
                      </Td>
                      <Td>{t.customer?.name ?? '—'}</Td>
                      <Td>
                        {t.vehicle ? (
                          `${fmtRegistration(t.vehicle.registrationNo)} · ${t.driver?.name ?? ''}`
                        ) : (
                          <span className="text-slate-500">Unassigned</span>
                        )}
                      </Td>
                      <Td align="right">{fmtInr(t.quotedFarePaise)}</Td>
                      <Td>
                        <TripStatusBadge status={t.status} />
                      </Td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            )
          }
        </QueryState>
      </Card>
      {creating && (
        <CreateTripModal
          onClose={() => {
            setCreating(false);
          }}
        />
      )}
    </>
  );
}
