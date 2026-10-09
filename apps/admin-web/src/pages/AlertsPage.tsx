import { Link } from 'react-router';
import { useState } from 'react';
import { SeverityBadge } from '../components/status.js';
import {
  Badge,
  Button,
  EmptyState,
  InlineError,
  PageHeader,
  QueryState,
  Select,
} from '../components/ui.js';
import { api, call } from '../lib/api.js';
import type { Alert } from '../lib/api-types.js';
import { fmtDateTime, humanize } from '../lib/format.js';
import { keys, useAlerts } from '../lib/queries.js';
import { useApiMutation } from '../lib/mutations.js';

const KIND_LABELS: Record<Alert['kind'], string> = {
  fuel_efficiency_low: 'Fuel use higher than usual',
  fuel_cost_high: 'Running cost higher than usual',
  odo_gps_mismatch: 'Odometer higher than GPS',
  document_expiring: 'Document expiring',
  document_expired: 'Document expired',
  cancellation_requested: 'Cancellation requested',
  gps_coverage_low: 'Poor GPS coverage',
};

const FUEL_KINDS: Alert['kind'][] = ['fuel_efficiency_low', 'fuel_cost_high'];

export interface AlertUpdate {
  status: 'acknowledged' | 'resolved' | 'dismissed';
  falsePositive?: boolean;
}

function subjectLink(alert: Alert): { to: string; label: string } | null {
  if (FUEL_KINDS.includes(alert.kind) && alert.vehicleId)
    return { to: `/fuel/${alert.vehicleId}`, label: 'Open fuel history' };
  if (alert.tripId) return { to: `/trips/${alert.tripId}`, label: 'Open trip' };
  if (alert.subjectType === 'document') return { to: '/documents', label: 'Open documents' };
  if (alert.vehicleId) return { to: `/vehicles/${alert.vehicleId}`, label: 'Open vehicle' };
  return null;
}

/** One alert with its actions. `onUpdate` sends the PATCH; kept as a prop for testing. */
export function AlertCard({
  alert,
  onUpdate,
  busy,
}: {
  alert: Alert;
  onUpdate: (update: AlertUpdate) => void;
  busy: boolean;
}) {
  const link = subjectLink(alert);
  const isOpen = alert.status === 'open' || alert.status === 'acknowledged';
  return (
    <article
      className="rounded-lg border border-slate-200 bg-white p-4 shadow-xs"
      aria-labelledby={`alert-${alert.id}`}
    >
      <div className="mb-2 flex flex-wrap items-center gap-2">
        <SeverityBadge severity={alert.severity} />
        <Badge>{KIND_LABELS[alert.kind]}</Badge>
        {alert.status !== 'open' && <Badge tone="neutral">{humanize(alert.status)}</Badge>}
        {alert.data['falsePositive'] === true && <Badge tone="info">False alarm</Badge>}
        <span className="ml-auto text-xs text-slate-500">{fmtDateTime(alert.createdAt)}</span>
      </div>
      <h2 id={`alert-${alert.id}`} className="font-medium text-slate-900">
        {alert.title}
      </h2>
      <p className="mt-1 text-sm text-slate-700">{alert.explanation}</p>
      <div className="mt-3 flex flex-wrap items-center gap-2">
        {link && (
          <Link to={link.to} className="text-sm font-medium text-brand-700 hover:underline">
            {link.label}
          </Link>
        )}
        {isOpen && (
          <span className="ml-auto flex flex-wrap gap-2">
            {alert.status === 'open' && (
              <Button
                size="sm"
                variant="ghost"
                disabled={busy}
                onClick={() => {
                  onUpdate({ status: 'acknowledged' });
                }}
              >
                Acknowledge
              </Button>
            )}
            {FUEL_KINDS.includes(alert.kind) && (
              <Button
                size="sm"
                variant="secondary"
                disabled={busy}
                onClick={() => {
                  onUpdate({ status: 'dismissed', falsePositive: true });
                }}
              >
                Dismiss as false alarm
              </Button>
            )}
            <Button
              size="sm"
              variant="secondary"
              disabled={busy}
              onClick={() => {
                onUpdate({ status: 'dismissed' });
              }}
            >
              Dismiss
            </Button>
            <Button
              size="sm"
              disabled={busy}
              onClick={() => {
                onUpdate({ status: 'resolved' });
              }}
            >
              Mark resolved
            </Button>
          </span>
        )}
      </div>
    </article>
  );
}

export function AlertsPage() {
  const [status, setStatus] = useState<Alert['status'] | ''>('open');
  const [kind, setKind] = useState<Alert['kind'] | ''>('');
  const alerts = useAlerts({
    ...(status ? { status } : {}),
    ...(kind ? { kind } : {}),
    limit: 200,
  });
  const update = useApiMutation(
    (input: { id: string; body: AlertUpdate }) =>
      call(api.PATCH('/alerts/{id}', { params: { path: { id: input.id } }, body: input.body })),
    [keys.alerts, keys.fuel],
  );

  return (
    <>
      <PageHeader
        title="Alerts"
        description="Dismissing a fuel alert as a false alarm lets that cycle count towards the vehicle’s normal range."
        actions={
          <>
            <Select
              aria-label="Status"
              className="w-40"
              value={status}
              onChange={(e) => {
                setStatus(e.target.value as typeof status);
              }}
            >
              <option value="open">Open</option>
              <option value="acknowledged">Acknowledged</option>
              <option value="resolved">Resolved</option>
              <option value="dismissed">Dismissed</option>
              <option value="">All</option>
            </Select>
            <Select
              aria-label="Kind"
              className="w-64"
              value={kind}
              onChange={(e) => {
                setKind(e.target.value as typeof kind);
              }}
            >
              <option value="">All kinds</option>
              {Object.entries(KIND_LABELS).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </Select>
          </>
        }
      />
      <InlineError error={update.error} />
      <QueryState query={alerts}>
        {(list) =>
          list.length === 0 ? (
            <EmptyState
              title={status === 'open' ? 'All clear: no open alerts' : 'No alerts match'}
            />
          ) : (
            <div className="space-y-3">
              {list.map((a) => (
                <AlertCard
                  key={a.id}
                  alert={a}
                  busy={update.isPending && update.variables.id === a.id}
                  onUpdate={(body) => {
                    update.mutate({ id: a.id, body });
                  }}
                />
              ))}
            </div>
          )
        }
      </QueryState>
    </>
  );
}
