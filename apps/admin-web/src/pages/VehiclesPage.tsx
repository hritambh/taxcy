import { RegistrationNo } from '@taxcy/contracts';
import { Plus } from 'lucide-react';
import { useState, type SubmitEvent } from 'react';
import { Link } from 'react-router';
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
  Table,
  Td,
  Th,
} from '../components/ui.js';
import { api, call } from '../lib/api.js';
import type { CreateVehicleBody, UpdateVehicleBody, Vehicle } from '../lib/api-types.js';
import { fmtKm, fmtRegistration } from '../lib/format.js';
import { FUEL_LABELS } from '../lib/labels.js';
import { useApiMutation } from '../lib/mutations.js';
import { keys, useVehicleModels, useVehicles } from '../lib/queries.js';

export function VehicleFormModal({
  open,
  onClose,
  vehicle,
}: {
  open: boolean;
  onClose: () => void;
  vehicle?: Vehicle;
}) {
  const models = useVehicleModels();
  const [form, setForm] = useState(() => ({
    registrationNo: vehicle?.registrationNo ?? '',
    make: vehicle?.make ?? '',
    model: vehicle?.model ?? '',
    year: vehicle?.year ? String(vehicle.year) : '',
    fuelType: vehicle?.fuelType ?? 'diesel',
    vehicleModelId: vehicle?.vehicleModelId ?? '',
    lastOdometerKm:
      vehicle?.lastOdometerKm === null || vehicle?.lastOdometerKm === undefined
        ? ''
        : String(vehicle.lastOdometerKm),
    status: vehicle?.status ?? 'active',
  }));
  const [regError, setRegError] = useState<string | null>(null);
  const save = useApiMutation(
    async (body: CreateVehicleBody & UpdateVehicleBody) =>
      vehicle
        ? call(api.PATCH('/vehicles/{id}', { params: { path: { id: vehicle.id } }, body }))
        : call(api.POST('/vehicles', { body })),
    [keys.vehicles],
  );

  function submit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    const reg = RegistrationNo.safeParse(form.registrationNo);
    if (!reg.success) {
      setRegError('Use a registration number like MH 12 AB 1234');
      return;
    }
    setRegError(null);
    save.mutate(
      {
        registrationNo: reg.data,
        make: form.make.trim(),
        model: form.model.trim(),
        fuelType: form.fuelType,
        ...(form.year ? { year: Number(form.year) } : {}),
        ...(form.vehicleModelId ? { vehicleModelId: form.vehicleModelId } : {}),
        ...(form.lastOdometerKm ? { lastOdometerKm: Number(form.lastOdometerKm) } : {}),
        ...(vehicle ? { status: form.status } : {}),
      },
      { onSuccess: onClose },
    );
  }

  const set = <K extends keyof typeof form>(key: K, value: (typeof form)[K]) => {
    setForm((f) => ({ ...f, [key]: value }));
  };

  return (
    <Modal open={open} onClose={onClose} title={vehicle ? 'Edit vehicle' : 'Add a vehicle'}>
      <form id="vehicle-form" onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
        <Field label="Registration number" error={regError} className="sm:col-span-2">
          {(props) => (
            <Input
              {...props}
              required
              placeholder="MH 12 AB 1234"
              value={form.registrationNo}
              onChange={(e) => {
                set('registrationNo', e.target.value);
              }}
            />
          )}
        </Field>
        <Field
          label="Known model"
          hint="Picking one seeds the fuel baseline for a new vehicle."
          className="sm:col-span-2"
        >
          {(props) => (
            <Select
              {...props}
              value={form.vehicleModelId}
              onChange={(e) => {
                const model = models.data?.find((m) => m.id === e.target.value);
                setForm((f) => ({
                  ...f,
                  vehicleModelId: e.target.value,
                  ...(model
                    ? { make: model.make, model: model.model, fuelType: model.fuelType }
                    : {}),
                }));
              }}
            >
              <option value="">Other / not listed</option>
              {models.data?.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.make} {m.model} ({FUEL_LABELS[m.fuelType]})
                </option>
              ))}
            </Select>
          )}
        </Field>
        <Field label="Make">
          {(props) => (
            <Input
              {...props}
              required
              value={form.make}
              onChange={(e) => {
                set('make', e.target.value);
              }}
            />
          )}
        </Field>
        <Field label="Model">
          {(props) => (
            <Input
              {...props}
              required
              value={form.model}
              onChange={(e) => {
                set('model', e.target.value);
              }}
            />
          )}
        </Field>
        <Field label="Fuel type" hint="Decides litres or kg, and how fuel is audited.">
          {(props) => (
            <Select
              {...props}
              value={form.fuelType}
              onChange={(e) => {
                set('fuelType', e.target.value as Vehicle['fuelType']);
              }}
            >
              {Object.entries(FUEL_LABELS).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </Select>
          )}
        </Field>
        <Field label="Year">
          {(props) => (
            <Input
              {...props}
              inputMode="numeric"
              value={form.year}
              onChange={(e) => {
                set('year', e.target.value.replace(/\D/g, '').slice(0, 4));
              }}
            />
          )}
        </Field>
        <Field label="Current odometer (km)" hint="Used to catch odometer rollbacks.">
          {(props) => (
            <Input
              {...props}
              inputMode="numeric"
              value={form.lastOdometerKm}
              onChange={(e) => {
                set('lastOdometerKm', e.target.value.replace(/\D/g, ''));
              }}
            />
          )}
        </Field>
        {vehicle && (
          <Field label="Status">
            {(props) => (
              <Select
                {...props}
                value={form.status}
                onChange={(e) => {
                  set('status', e.target.value as Vehicle['status']);
                }}
              >
                <option value="active">Active</option>
                <option value="inactive">Inactive (hidden from assignment)</option>
              </Select>
            )}
          </Field>
        )}
        <div className="sm:col-span-2">
          <InlineError error={save.error} />
        </div>
        <div className="flex justify-end gap-2 sm:col-span-2">
          <Button variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" busy={save.isPending}>
            {vehicle ? 'Save' : 'Add vehicle'}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

export function VehiclesPage() {
  const [status, setStatus] = useState<'' | 'active' | 'inactive'>('');
  const vehicles = useVehicles(status || undefined);
  const [creating, setCreating] = useState(false);

  return (
    <>
      <PageHeader
        title="Vehicles"
        actions={
          <>
            <Select
              aria-label="Filter by status"
              className="w-40"
              value={status}
              onChange={(e) => {
                setStatus(e.target.value as typeof status);
              }}
            >
              <option value="">All vehicles</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </Select>
            <Button
              onClick={() => {
                setCreating(true);
              }}
            >
              <Plus className="size-4" aria-hidden />
              Add vehicle
            </Button>
          </>
        }
      />
      <Card>
        <QueryState query={vehicles}>
          {(list) =>
            list.length === 0 ? (
              <EmptyState title="No vehicles yet">
                Add your first car to start assigning trips.
              </EmptyState>
            ) : (
              <Table>
                <thead>
                  <tr>
                    <Th>Registration</Th>
                    <Th>Vehicle</Th>
                    <Th>Fuel</Th>
                    <Th align="right">Odometer</Th>
                    <Th>Status</Th>
                  </tr>
                </thead>
                <tbody>
                  {list.map((v) => (
                    <tr key={v.id} className="hover:bg-slate-50">
                      <Td>
                        <Link
                          className="font-medium text-brand-700 hover:underline"
                          to={`/vehicles/${v.id}`}
                        >
                          {fmtRegistration(v.registrationNo)}
                        </Link>
                      </Td>
                      <Td>
                        {v.make} {v.model}
                        {v.year ? ` (${String(v.year)})` : ''}
                      </Td>
                      <Td>{FUEL_LABELS[v.fuelType]}</Td>
                      <Td align="right">{fmtKm(v.lastOdometerKm)}</Td>
                      <Td>
                        {v.status === 'active' ? (
                          <Badge tone="success">Active</Badge>
                        ) : (
                          <Badge>Inactive</Badge>
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
      {creating && (
        <VehicleFormModal
          open
          onClose={() => {
            setCreating(false);
          }}
        />
      )}
    </>
  );
}
