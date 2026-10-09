import { Plus } from 'lucide-react';
import { useState, type SubmitEvent } from 'react';
import { Link } from 'react-router';
import { DriverSelect, Photo, VehicleSelect } from '../components/shared.js';
import { DocumentStatusBadge } from '../components/status.js';
import { DOC_NAMES } from '../lib/labels.js';
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
import type { DocumentRow } from '../lib/api-types.js';
import { fmtDate, fmtRegistration, istToday } from '../lib/format.js';
import {
  keys,
  useDocuments,
  useDrivers,
  useVehicles,
  type DocumentFilter,
} from '../lib/queries.js';
import { useApiMutation } from '../lib/mutations.js';

type DocType = DocumentRow['docType'];
const VEHICLE_DOCS: DocType[] = ['rc', 'insurance', 'permit', 'puc'];

function DocumentFormModal({
  onClose,
  renewing,
  subject,
}: {
  onClose: () => void;
  renewing?: DocumentRow;
  subject?: { vehicleId?: string; driverId?: string };
}) {
  const [docType, setDocType] = useState<DocType>(
    renewing?.docType ?? (subject?.driverId ? 'driving_licence' : 'insurance'),
  );
  const [vehicleId, setVehicleId] = useState(subject?.vehicleId ?? '');
  const [driverId, setDriverId] = useState(subject?.driverId ?? '');
  const [number, setNumber] = useState(renewing?.number ?? '');
  const [validFrom, setValidFrom] = useState('');
  const [expiresOn, setExpiresOn] = useState('');
  const forDriver = docType === 'driving_licence';

  const save = useApiMutation(async () => {
    const details = {
      expiresOn,
      ...(number.trim() ? { number: number.trim() } : {}),
      ...(validFrom ? { validFrom } : {}),
    };
    if (renewing) {
      return call(
        api.POST('/documents/{id}/renew', { params: { path: { id: renewing.id } }, body: details }),
      );
    }
    return call(
      api.POST('/documents', {
        body: { ...details, docType, ...(forDriver ? { driverId } : { vehicleId }) },
      }),
    );
  }, [keys.documents, keys.alerts]);

  function submit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    save.mutate(undefined, { onSuccess: onClose });
  }

  const subjectMissing = !renewing && (forDriver ? !driverId : !vehicleId);

  return (
    <Modal
      open
      onClose={onClose}
      title={renewing ? `Renew ${DOC_NAMES[renewing.docType].toLowerCase()}` : 'Add a document'}
    >
      <form onSubmit={submit} className="grid gap-4 sm:grid-cols-2">
        {renewing ? (
          <p className="text-sm text-slate-600 sm:col-span-2">
            The renewed copy replaces the current one (it stays in history), and its expiry alerts
            are cleared.
          </p>
        ) : (
          <>
            <Field label="Document" className="sm:col-span-2">
              {(props) => (
                <Select
                  {...props}
                  value={docType}
                  onChange={(e) => {
                    setDocType(e.target.value as DocType);
                  }}
                  disabled={Boolean(subject?.vehicleId ?? subject?.driverId)}
                >
                  {(subject?.vehicleId
                    ? VEHICLE_DOCS
                    : subject?.driverId
                      ? (['driving_licence'] as DocType[])
                      : [...VEHICLE_DOCS, 'driving_licence' as const]
                  ).map((t) => (
                    <option key={t} value={t}>
                      {DOC_NAMES[t]}
                    </option>
                  ))}
                </Select>
              )}
            </Field>
            {!subject && (
              <Field label={forDriver ? 'Driver' : 'Vehicle'} className="sm:col-span-2">
                {(props) =>
                  forDriver ? (
                    <DriverSelect {...props} value={driverId} onChange={setDriverId} required />
                  ) : (
                    <VehicleSelect {...props} value={vehicleId} onChange={setVehicleId} required />
                  )
                }
              </Field>
            )}
          </>
        )}
        <Field label="Number">
          {(props) => (
            <Input
              {...props}
              value={number}
              onChange={(e) => {
                setNumber(e.target.value);
              }}
            />
          )}
        </Field>
        <Field label="Valid from">
          {(props) => (
            <Input
              {...props}
              type="date"
              value={validFrom}
              onChange={(e) => {
                setValidFrom(e.target.value);
              }}
            />
          )}
        </Field>
        <Field label="Expires on" hint="Alerts are raised 30, 7 and 1 days before, and on expiry.">
          {(props) => (
            <Input
              {...props}
              type="date"
              required
              min={renewing ? istToday() : undefined}
              value={expiresOn}
              onChange={(e) => {
                setExpiresOn(e.target.value);
              }}
            />
          )}
        </Field>
        <div className="sm:col-span-2">
          <InlineError error={save.error} />
        </div>
        <div className="flex justify-end gap-2 sm:col-span-2">
          <Button variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" busy={save.isPending} disabled={!expiresOn || subjectMissing}>
            {renewing ? 'Save renewal' : 'Add document'}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

/** Documents table with add/renew; scoped to one vehicle or driver when `subject` is given. */
export function DocumentsTable({
  filter,
  subject,
}: {
  filter: DocumentFilter;
  subject?: { vehicleId?: string; driverId?: string };
}) {
  const documents = useDocuments(filter);
  const vehicles = useVehicles();
  const drivers = useDrivers();
  const [adding, setAdding] = useState(false);
  const [renewing, setRenewing] = useState<DocumentRow | null>(null);
  const [viewing, setViewing] = useState<DocumentRow | null>(null);

  const subjectName = (d: DocumentRow) => {
    if (d.vehicleId) {
      const v = vehicles.data?.find((x) => x.id === d.vehicleId);
      return v ? (
        <Link className="text-brand-700 hover:underline" to={`/vehicles/${v.id}`}>
          {fmtRegistration(v.registrationNo)}
        </Link>
      ) : (
        '—'
      );
    }
    return drivers.data?.find((x) => x.id === d.driverId)?.name ?? '—';
  };

  return (
    <Card
      title={subject ? 'Documents' : undefined}
      actions={
        <Button
          size="sm"
          onClick={() => {
            setAdding(true);
          }}
        >
          <Plus className="size-4" aria-hidden />
          Add document
        </Button>
      }
    >
      <QueryState query={documents}>
        {(list) =>
          list.length === 0 ? (
            <EmptyState title="No documents">
              Add RC, insurance, permit and PUC for vehicles, and licences for drivers.
            </EmptyState>
          ) : (
            <Table>
              <thead>
                <tr>
                  <Th>Document</Th>
                  {!subject && <Th>For</Th>}
                  <Th>Number</Th>
                  <Th>Expires</Th>
                  <Th>Status</Th>
                  <Th />
                </tr>
              </thead>
              <tbody>
                {list.map((d) => (
                  <tr key={d.id}>
                    <Td className="font-medium">{DOC_NAMES[d.docType]}</Td>
                    {!subject && <Td>{subjectName(d)}</Td>}
                    <Td>{d.number ?? '—'}</Td>
                    <Td>{fmtDate(d.expiresOn)}</Td>
                    <Td>
                      <DocumentStatusBadge doc={d} />
                    </Td>
                    <Td className="text-right whitespace-nowrap">
                      {d.mediaId && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => {
                            setViewing(d);
                          }}
                        >
                          View
                        </Button>
                      )}
                      {d.status !== 'superseded' && (
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => {
                            setRenewing(d);
                          }}
                        >
                          Renew
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
      {adding && (
        <DocumentFormModal
          {...(subject ? { subject } : {})}
          onClose={() => {
            setAdding(false);
          }}
        />
      )}
      {renewing && (
        <DocumentFormModal
          renewing={renewing}
          onClose={() => {
            setRenewing(null);
          }}
        />
      )}
      <Modal
        open={viewing !== null}
        onClose={() => {
          setViewing(null);
        }}
        title={viewing ? DOC_NAMES[viewing.docType] : ''}
      >
        <Photo
          mediaId={viewing?.mediaId}
          alt="Document scan"
          className="max-h-[60vh] w-full object-contain"
        />
      </Modal>
    </Card>
  );
}

const WINDOWS = [
  { id: 'all', label: 'All current documents' },
  { id: '30', label: 'Due in 30 days or expired' },
  { id: '7', label: 'Due in 7 days or expired' },
  { id: '0', label: 'Expired or due today' },
] as const;

export function DocumentsPage() {
  const [window, setWindow] = useState<(typeof WINDOWS)[number]['id']>('all');
  const filter: DocumentFilter = window === 'all' ? {} : { expiringWithinDays: Number(window) };
  return (
    <>
      <PageHeader
        title="Documents"
        description="Alerts are raised 30, 7 and 1 days before expiry, and again when a document expires."
        actions={
          <Select
            aria-label="Filter documents"
            className="w-60"
            value={window}
            onChange={(e) => {
              setWindow(e.target.value as typeof window);
            }}
          >
            {WINDOWS.map((w) => (
              <option key={w.id} value={w.id}>
                {w.label}
              </option>
            ))}
          </Select>
        }
      />
      <DocumentsTable filter={filter} />
    </>
  );
}
