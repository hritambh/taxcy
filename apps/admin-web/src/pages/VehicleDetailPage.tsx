import { useState } from 'react';
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
import { FUEL_LABELS } from '../lib/labels.js';
import { useTrips, useVehicle } from '../lib/queries.js';
import { DocumentsTable } from './DocumentsPage.js';
import { VehicleFuelPanel } from './FuelPages.js';
import { VehicleFormModal } from './VehiclesPage.js';

const TABS = [
  { id: 'documents', label: 'Documents' },
  { id: 'fuel', label: 'Fuel' },
  { id: 'trips', label: 'Recent trips' },
] as const;

function VehicleTrips({ vehicleId }: { vehicleId: string }) {
  const trips = useTrips({ vehicleId, limit: 50 });
  return (
    <Card>
      <QueryState query={trips}>
        {(list) =>
          list.length === 0 ? (
            <EmptyState title="No trips yet" />
          ) : (
            <Table>
              <thead>
                <tr>
                  <Th>Scheduled</Th>
                  <Th>Route</Th>
                  <Th>Driver</Th>
                  <Th align="right">Fare</Th>
                  <Th>Status</Th>
                </tr>
              </thead>
              <tbody>
                {list.map((t) => (
                  <tr key={t.id} className="hover:bg-slate-50">
                    <Td>{fmtDateTime(t.scheduledStartAt)}</Td>
                    <Td>
                      <Link className="text-brand-700 hover:underline" to={`/trips/${t.id}`}>
                        {t.from.text}
                        {t.to ? ` → ${t.to.text}` : ''}
                      </Link>
                    </Td>
                    <Td>{t.driver?.name ?? '—'}</Td>
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
  );
}

export function VehicleDetailPage() {
  const { id = '' } = useParams();
  const vehicle = useVehicle(id);
  const [tab, setTab] = useState<(typeof TABS)[number]['id']>('documents');
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
                Edit
              </Button>
            }
          />
          <Card className="mb-4">
            <dl className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              <Stat label="Fuel" value={FUEL_LABELS[v.fuelType]} />
              <Stat label="Last odometer" value={fmtKm(v.lastOdometerKm)} />
              <Stat
                label="Status"
                value={
                  v.status === 'active' ? (
                    <Badge tone="success">Active</Badge>
                  ) : (
                    <Badge>Inactive</Badge>
                  )
                }
              />
              <Stat label="Added" value={fmtDateTime(v.createdAt)} />
            </dl>
          </Card>
          <Tabs tabs={TABS} value={tab} onChange={setTab} />
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
