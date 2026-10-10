import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useParams } from 'react-router';
import { TripStatusBadge } from '../components/status.js';
import {
  Badge,
  Button,
  Card,
  EmptyState,
  PageHeader,
  QueryState,
  Stat,
  Table,
  Tabs,
  Td,
  Th,
} from '../components/ui.js';
import { fmtDateTime, fmtInr, fmtKm, fmtRegistration } from '../lib/format.js';
import { useTrips, useVehicle } from '../lib/queries.js';
import { DocumentsTable } from './DocumentsPage.js';
import { VehicleFuelPanel } from './FuelPages.js';
import { VehicleFormModal } from './VehiclesPage.js';

type Tab = 'documents' | 'fuel' | 'trips';

function VehicleTrips({ vehicleId }: { vehicleId: string }) {
  const { t } = useTranslation();
  const trips = useTrips({ vehicleId, limit: 50 });
  return (
    <Card>
      <QueryState query={trips}>
        {(list) =>
          list.length === 0 ? (
            <EmptyState title={t('fleet.vehicleDetail.noTrips')} />
          ) : (
            <Table>
              <thead>
                <tr>
                  <Th>{t('fleet.vehicleDetail.col.scheduled')}</Th>
                  <Th>{t('fleet.vehicleDetail.col.route')}</Th>
                  <Th>{t('fleet.vehicleDetail.col.driver')}</Th>
                  <Th align="right">{t('fleet.vehicleDetail.col.fare')}</Th>
                  <Th>{t('fleet.vehicleDetail.col.status')}</Th>
                </tr>
              </thead>
              <tbody>
                {list.map((trip) => (
                  <tr key={trip.id} className="hover:bg-slate-50">
                    <Td>{fmtDateTime(trip.scheduledStartAt)}</Td>
                    <Td>
                      <Link className="text-brand-700 hover:underline" to={`/trips/${trip.id}`}>
                        {trip.to
                          ? t('common.route', { from: trip.from.text, to: trip.to.text })
                          : trip.from.text}
                      </Link>
                    </Td>
                    <Td>{trip.driver?.name ?? '—'}</Td>
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
  );
}

export function VehicleDetailPage() {
  const { t } = useTranslation();
  const { id = '' } = useParams();
  const vehicle = useVehicle(id);
  const [tab, setTab] = useState<Tab>('documents');
  const tabs: { id: Tab; label: string }[] = [
    { id: 'documents', label: t('fleet.vehicleDetail.tabDocuments') },
    { id: 'fuel', label: t('fleet.vehicleDetail.tabFuel') },
    { id: 'trips', label: t('fleet.vehicleDetail.tabTrips') },
  ];
  const [editing, setEditing] = useState(false);

  return (
    <QueryState query={vehicle}>
      {(v) => (
        <>
          <PageHeader
            title={fmtRegistration(v.registrationNo)}
            description={`${v.make} ${v.model}${v.year ? ` · ${String(v.year)}` : ''}`}
            actions={
              <Button
                variant="secondary"
                onClick={() => {
                  setEditing(true);
                }}
              >
                {t('fleet.vehicleDetail.edit')}
              </Button>
            }
          />
          <Card className="mb-4">
            <dl className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <Stat
                label={t('fleet.vehicleDetail.fuel')}
                value={t(`enums.fuelType.${v.fuelType}`)}
              />
              <Stat label={t('fleet.vehicleDetail.lastOdometer')} value={fmtKm(v.lastOdometerKm)} />
              <Stat
                label={t('fleet.vehicleDetail.status')}
                value={
                  v.status === 'active' ? (
                    <Badge tone="success">{t('enums.activeStatus.active')}</Badge>
                  ) : (
                    <Badge>{t('enums.activeStatus.inactive')}</Badge>
                  )
                }
              />
              <Stat label={t('fleet.vehicleDetail.added')} value={fmtDateTime(v.createdAt)} />
            </dl>
          </Card>
          <Tabs tabs={tabs} value={tab} onChange={setTab} />
          {tab === 'documents' && (
            <DocumentsTable filter={{ vehicleId: id }} subject={{ vehicleId: id }} />
          )}
          {tab === 'fuel' && <VehicleFuelPanel vehicleId={id} />}
          {tab === 'trips' && <VehicleTrips vehicleId={id} />}
          {editing && (
            <VehicleFormModal
              open
              vehicle={v}
              onClose={() => {
                setEditing(false);
              }}
            />
          )}
        </>
      )}
    </QueryState>
  );
}
