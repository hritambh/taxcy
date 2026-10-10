import { Plus } from 'lucide-react';
import { useState, type SubmitEvent } from 'react';
import { useTranslation } from 'react-i18next';
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
const TRIP_TYPES: Trip['tripType'][] = ['one_way', 'round_trip', 'local_rental'];

function CreateTripModal({ onClose }: { onClose: () => void }) {
  const { t } = useTranslation();
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
  const [includedKm, setIncludedKm] = useState('');
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
    const km = includedKm.trim() === '' ? null : Number(includedKm.trim());
    const problemText =
      quotedFarePaise === null
        ? t('trips.create.fareInvalid')
        : km !== null && (!Number.isInteger(km) || km < 1 || km > 20_000)
          ? t('trips.create.includedKmInvalid')
          : !start || !end || end <= start
            ? t('trips.create.endBeforeStart')
            : Boolean(vehicleId) !== Boolean(driverId)
              ? t('trips.create.pickBoth')
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
        ...(km !== null ? { includedKm: km } : {}),
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
    <Modal open wide onClose={onClose} title={t('trips.newTrip')}>
      <form onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
        <Field label={t('trips.create.tripType')}>
          {(props) => (
            <Select
              {...props}
              value={tripType}
              onChange={(e) => {
                setTripType(e.target.value as Trip['tripType']);
              }}
            >
              {TRIP_TYPES.map((type) => (
                <option key={type} value={type}>
                  {t(`enums.tripType.${type}`)}
                </option>
              ))}
            </Select>
          )}
        </Field>
        <Field label={t('trips.create.quotedFare')}>
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
        <Field label={t('trips.create.includedKm')} hint={t('trips.create.includedKmHint')}>
          {(props) => (
            <Input
              {...props}
              inputMode="numeric"
              placeholder="300"
              value={includedKm}
              onChange={(e) => {
                setIncludedKm(e.target.value);
              }}
            />
          )}
        </Field>
        <Field label={t('trips.create.customerName')}>
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
        <Field label={t('trips.create.customerMobile')}>
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
        <Field label={t('trips.create.pickup')}>
          {(props) => (
            <div className="space-y-2">
              <Input
                {...props}
                required
                placeholder={t('trips.create.pickupPlaceholder')}
                value={fromText}
                onChange={(e) => {
                  setFromText(e.target.value);
                }}
              />
              <PointPicker
                value={fromPoint}
                onChange={setFromPoint}
                label={t('trips.create.pickup')}
              />
            </div>
          )}
        </Field>
        {tripType !== 'local_rental' ? (
          <Field label={t('trips.create.drop')}>
            {(props) => (
              <div className="space-y-2">
                <Input
                  {...props}
                  required
                  placeholder={t('trips.create.dropPlaceholder')}
                  value={toText}
                  onChange={(e) => {
                    setToText(e.target.value);
                  }}
                />
                <PointPicker value={toPoint} onChange={setToPoint} label={t('trips.create.drop')} />
              </div>
            )}
          </Field>
        ) : (
          <div />
        )}
        <Field label={t('trips.create.starts')}>
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
        <Field label={t('trips.create.ends')}>
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
        <Field label={t('trips.create.vehicleOptional')}>
          {(props) => (
            <VehicleSelect
              {...props}
              value={vehicleId}
              onChange={setVehicleId}
              placeholder={t('trips.create.assignLater')}
            />
          )}
        </Field>
        <Field label={t('trips.create.driverOptional')}>
          {(props) => (
            <DriverSelect
              {...props}
              value={driverId}
              onChange={setDriverId}
              placeholder={t('trips.create.assignLater')}
            />
          )}
        </Field>
        <div className="space-y-2 sm:col-span-2">
          {problem && <p className="text-sm text-red-600">{problem}</p>}
          <InlineError error={create.error} />
        </div>
        <div className="flex justify-end gap-2 sm:col-span-2">
          <Button variant="secondary" onClick={onClose}>
            {t('common.cancel')}
          </Button>
          <Button type="submit" busy={create.isPending}>
            {t('trips.create.submit')}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

export function TripsPage() {
  const { t } = useTranslation();
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
        title={t('trips.title')}
        actions={
          <Button
            onClick={() => {
              setCreating(true);
            }}
          >
            <Plus className="size-4" aria-hidden />
            {t('trips.newTrip')}
          </Button>
        }
      />
      <div className="mb-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
        <Select
          aria-label={t('common.status')}
          value={status}
          onChange={(e) => {
            setParam('status', e.target.value);
          }}
        >
          <option value="">{t('trips.allStatuses')}</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {t(`enums.tripStatus.${s}`)}
            </option>
          ))}
        </Select>
        <Input
          aria-label={t('trips.dateIst')}
          type="date"
          value={date}
          max={istToday()}
          onChange={(e) => {
            setParam('date', e.target.value);
          }}
        />
        <DriverSelect
          aria-label={t('trips.driver')}
          value={driverId}
          placeholder={t('trips.allDrivers')}
          onChange={(v) => {
            setParam('driverId', v);
          }}
        />
        <VehicleSelect
          aria-label={t('trips.vehicle')}
          value={vehicleId}
          placeholder={t('trips.allVehicles')}
          onChange={(v) => {
            setParam('vehicleId', v);
          }}
        />
      </div>
      <Card>
        <QueryState query={trips}>
          {(list) =>
            list.length === 0 ? (
              <EmptyState title={t('trips.noneMatch')} />
            ) : (
              <Table>
                <thead>
                  <tr>
                    <Th>{t('trips.col.scheduled')}</Th>
                    <Th>{t('trips.col.route')}</Th>
                    <Th>{t('trips.col.customer')}</Th>
                    <Th>{t('trips.col.vehicleDriver')}</Th>
                    <Th align="right">{t('trips.col.fare')}</Th>
                    <Th>{t('trips.col.status')}</Th>
                  </tr>
                </thead>
                <tbody>
                  {list.map((trip) => (
                    <tr key={trip.id} className="hover:bg-slate-50">
                      <Td className="whitespace-nowrap">{fmtDateTime(trip.scheduledStartAt)}</Td>
                      <Td>
                        <Link
                          className="font-medium text-brand-700 hover:underline"
                          to={`/trips/${trip.id}`}
                        >
                          {trip.to
                            ? t('common.route', { from: trip.from.text, to: trip.to.text })
                            : t('trips.localRoute', { from: trip.from.text })}
                        </Link>
                      </Td>
                      <Td>{trip.customer?.name ?? '—'}</Td>
                      <Td>
                        {trip.vehicle ? (
                          `${fmtRegistration(trip.vehicle.registrationNo)} · ${trip.driver?.name ?? ''}`
                        ) : (
                          <span className="text-slate-500">{t('common.unassigned')}</span>
                        )}
                      </Td>
                      <Td align="right">{fmtInr(trip.quotedFarePaise)}</Td>
                      <Td>
                        <TripStatusBadge status={trip.status} />
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
