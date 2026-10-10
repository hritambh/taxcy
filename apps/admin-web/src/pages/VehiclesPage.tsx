import { RegistrationNo } from '@taxcy/contracts';
import { Plus } from 'lucide-react';
import { useState, type SubmitEvent } from 'react';
import { useTranslation } from 'react-i18next';
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
import { useApiMutation } from '../lib/mutations.js';
import { keys, useVehicleModels, useVehicles } from '../lib/queries.js';

const FUEL_TYPES: Vehicle['fuelType'][] = ['petrol', 'diesel', 'cng', 'petrol_cng'];

export function VehicleFormModal({
  open,
  onClose,
  vehicle,
}: {
  open: boolean;
  onClose: () => void;
  vehicle?: Vehicle;
}) {
  const { t } = useTranslation();
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
      setRegError(t('fleet.vehicleForm.registrationInvalid'));
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
    <Modal
      open={open}
      onClose={onClose}
      title={vehicle ? t('fleet.vehicleForm.editTitle') : t('fleet.vehicleForm.addTitle')}
    >
      <form id="vehicle-form" onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
        <Field
          label={t('fleet.vehicleForm.registrationNo')}
          error={regError}
          className="sm:col-span-2"
        >
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
          label={t('fleet.vehicleForm.knownModel')}
          hint={t('fleet.vehicleForm.knownModelHint')}
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
              <option value="">{t('fleet.vehicleForm.otherModel')}</option>
              {models.data?.map((m) => (
                <option key={m.id} value={m.id}>
                  {t('fleet.vehicleForm.modelOption', {
                    make: m.make,
                    model: m.model,
                    fuel: t(`enums.fuelType.${m.fuelType}`),
                  })}
                </option>
              ))}
            </Select>
          )}
        </Field>
        <Field label={t('fleet.vehicleForm.make')}>
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
        <Field label={t('fleet.vehicleForm.model')}>
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
        <Field label={t('fleet.vehicleForm.fuelType')} hint={t('fleet.vehicleForm.fuelTypeHint')}>
          {(props) => (
            <Select
              {...props}
              value={form.fuelType}
              onChange={(e) => {
                set('fuelType', e.target.value as Vehicle['fuelType']);
              }}
            >
              {FUEL_TYPES.map((value) => (
                <option key={value} value={value}>
                  {t(`enums.fuelType.${value}`)}
                </option>
              ))}
            </Select>
          )}
        </Field>
        <Field label={t('fleet.vehicleForm.year')}>
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
        <Field
          label={t('fleet.vehicleForm.currentOdometer')}
          hint={t('fleet.vehicleForm.currentOdometerHint')}
        >
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
          <Field label={t('fleet.vehicleForm.status')}>
            {(props) => (
              <Select
                {...props}
                value={form.status}
                onChange={(e) => {
                  set('status', e.target.value as Vehicle['status']);
                }}
              >
                <option value="active">{t('enums.activeStatus.active')}</option>
                <option value="inactive">{t('fleet.vehicleForm.inactiveHidden')}</option>
              </Select>
            )}
          </Field>
        )}
        <div className="sm:col-span-2">
          <InlineError error={save.error} />
        </div>
        <div className="flex justify-end gap-2 sm:col-span-2">
          <Button variant="secondary" onClick={onClose}>
            {t('common.cancel')}
          </Button>
          <Button type="submit" busy={save.isPending}>
            {vehicle ? t('common.save') : t('fleet.vehicles.addVehicle')}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

export function VehiclesPage() {
  const { t } = useTranslation();
  const [status, setStatus] = useState<'' | 'active' | 'inactive'>('');
  const vehicles = useVehicles(status || undefined);
  const [creating, setCreating] = useState(false);

  return (
    <>
      <PageHeader
        title={t('nav.vehicles')}
        actions={
          <>
            <Select
              aria-label={t('fleet.vehicles.filterByStatus')}
              className="w-40"
              value={status}
              onChange={(e) => {
                setStatus(e.target.value as typeof status);
              }}
            >
              <option value="">{t('fleet.vehicles.allVehicles')}</option>
              <option value="active">{t('enums.activeStatus.active')}</option>
              <option value="inactive">{t('enums.activeStatus.inactive')}</option>
            </Select>
            <Button
              onClick={() => {
                setCreating(true);
              }}
            >
              <Plus className="size-4" aria-hidden />
              {t('fleet.vehicles.addVehicle')}
            </Button>
          </>
        }
      />
      <Card>
        <QueryState query={vehicles}>
          {(list) =>
            list.length === 0 ? (
              <EmptyState title={t('fleet.vehicles.noVehicles')}>
                {t('fleet.vehicles.noVehiclesHint')}
              </EmptyState>
            ) : (
              <Table>
                <thead>
                  <tr>
                    <Th>{t('fleet.vehicles.col.registration')}</Th>
                    <Th>{t('fleet.vehicles.col.vehicle')}</Th>
                    <Th>{t('fleet.vehicles.col.fuel')}</Th>
                    <Th align="right">{t('fleet.vehicles.col.odometer')}</Th>
                    <Th>{t('fleet.vehicles.col.status')}</Th>
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
                      <Td>{t(`enums.fuelType.${v.fuelType}`)}</Td>
                      <Td align="right">{fmtKm(v.lastOdometerKm)}</Td>
                      <Td>
                        {v.status === 'active' ? (
                          <Badge tone="success">{t('enums.activeStatus.active')}</Badge>
                        ) : (
                          <Badge>{t('enums.activeStatus.inactive')}</Badge>
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
