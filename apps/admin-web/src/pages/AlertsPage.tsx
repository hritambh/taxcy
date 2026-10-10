import { AlertKind } from '@taxcy/contracts';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router';
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
import { alertText } from '../lib/alert-text.js';
import { fmtDateTime } from '../lib/format.js';
import { keys, useAlerts } from '../lib/queries.js';
import { useApiMutation } from '../lib/mutations.js';

const FUEL_KINDS: Alert['kind'][] = ['fuel_efficiency_low', 'fuel_cost_high'];

export interface AlertUpdate {
  status: 'acknowledged' | 'resolved' | 'dismissed';
  falsePositive?: boolean;
}

function subjectLink(
  alert: Alert,
): { to: string; label: 'openFuelHistory' | 'openTrip' | 'openDocuments' | 'openVehicle' } | null {
  if (FUEL_KINDS.includes(alert.kind) && alert.vehicleId)
    return { to: `/fuel/${alert.vehicleId}`, label: 'openFuelHistory' };
  if (alert.tripId) return { to: `/trips/${alert.tripId}`, label: 'openTrip' };
  if (alert.subjectType === 'document') return { to: '/documents', label: 'openDocuments' };
  if (alert.vehicleId) return { to: `/vehicles/${alert.vehicleId}`, label: 'openVehicle' };
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
  const { t } = useTranslation();
  const link = subjectLink(alert);
  const text = alertText(alert);
  const isOpen = alert.status === 'open' || alert.status === 'acknowledged';
  return (
    <article
      className="rounded-lg border border-slate-200 bg-white p-4 shadow-xs"
      aria-labelledby={`alert-${alert.id}`}
    >
      <div className="mb-2 flex flex-wrap items-center gap-2">
        <SeverityBadge severity={alert.severity} />
        <Badge>{t(`enums.alertKind.${alert.kind}`)}</Badge>
        {alert.status !== 'open' && (
          <Badge tone="neutral">{t(`enums.alertStatus.${alert.status}`)}</Badge>
        )}
        {alert.data['falsePositive'] === true && (
          <Badge tone="info">{t('alerts.falseAlarm')}</Badge>
        )}
        <span className="ml-auto text-xs text-slate-500">{fmtDateTime(alert.createdAt)}</span>
      </div>
      <h2 id={`alert-${alert.id}`} className="font-medium text-slate-900">
        {text.title}
      </h2>
      <p className="mt-1 text-sm text-slate-700">{text.explanation}</p>
      <div className="mt-3 flex flex-wrap items-center gap-2">
        {link && (
          <Link to={link.to} className="text-sm font-medium text-brand-700 hover:underline">
            {t(`alerts.${link.label}`)}
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
                {t('alerts.acknowledge')}
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
                {t('alerts.dismissFalseAlarm')}
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
              {t('common.dismiss')}
            </Button>
            <Button
              size="sm"
              disabled={busy}
              onClick={() => {
                onUpdate({ status: 'resolved' });
              }}
            >
              {t('alerts.markResolved')}
            </Button>
          </span>
        )}
      </div>
    </article>
  );
}

export function AlertsPage() {
  const { t } = useTranslation();
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
        title={t('alerts.title')}
        description={t('alerts.description')}
        actions={
          <>
            <Select
              aria-label={t('common.status')}
              className="w-40"
              value={status}
              onChange={(e) => {
                setStatus(e.target.value as typeof status);
              }}
            >
              {(['open', 'acknowledged', 'resolved', 'dismissed'] as const).map((s) => (
                <option key={s} value={s}>
                  {t(`enums.alertStatus.${s}`)}
                </option>
              ))}
              <option value="">{t('common.all')}</option>
            </Select>
            <Select
              aria-label={t('alerts.kind')}
              className="w-64"
              value={kind}
              onChange={(e) => {
                setKind(e.target.value as typeof kind);
              }}
            >
              <option value="">{t('alerts.allKinds')}</option>
              {AlertKind.options.map((value) => (
                <option key={value} value={value}>
                  {t(`enums.alertKind.${value}`)}
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
            <EmptyState title={status === 'open' ? t('alerts.allClear') : t('alerts.noneMatch')} />
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
