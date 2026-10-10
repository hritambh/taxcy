import { useTranslation } from 'react-i18next';
import { Link } from 'react-router';
import { DocumentStatusBadge, SeverityBadge, TripStatusBadge } from '../components/status.js';
import { Card, EmptyState, PageHeader, QueryState } from '../components/ui.js';
import { alertText } from '../lib/alert-text.js';
import type { Alert, TripStatus } from '../lib/api-types.js';
import { fmtDate, fmtDateTime, fmtTime, istDayRange, istToday } from '../lib/format.js';
import { useAlerts, useAlertSummary, useDocuments, useTrips } from '../lib/queries.js';

const SEVERITY_ORDER: Record<Alert['severity'], number> = { critical: 0, warning: 1, info: 2 };
const STATUSES: TripStatus[] = ['created', 'assigned', 'started', 'ended', 'settled', 'cancelled'];

export function DashboardPage() {
  const { t } = useTranslation();
  const today = istToday();
  const trips = useTrips({ ...istDayRange(today), limit: 200 });
  const alerts = useAlerts({ status: 'open', limit: 100 });
  const summary = useAlertSummary();
  const documents = useDocuments({ expiringWithinDays: 30 });

  return (
    <>
      <PageHeader title={t('dashboard.title')} description={fmtDate(today)} />
      <div className="grid gap-4 lg:grid-cols-3">
        <Card
          title={t('dashboard.todaysTrips')}
          className="lg:col-span-2"
          actions={
            <Link className="text-sm text-brand-700 hover:underline" to="/trips">
              {t('dashboard.allTrips')}
            </Link>
          }
        >
          <QueryState query={trips}>
            {(list) => (
              <>
                <dl className="mb-4 grid grid-cols-3 gap-3 sm:grid-cols-6">
                  {STATUSES.map((status) => (
                    <div
                      key={status}
                      className="rounded-lg border border-brand-100 bg-brand-50 p-2 text-center"
                    >
                      <dd className="tabular text-xl font-semibold text-brand-800">
                        {list.filter((t) => t.status === status).length}
                      </dd>
                      <dt className="text-xs text-slate-500">{t(`enums.tripStatus.${status}`)}</dt>
                    </div>
                  ))}
                </dl>
                {list.length === 0 ? (
                  <EmptyState title={t('dashboard.noTripsToday')} />
                ) : (
                  <ul className="divide-y divide-slate-100">
                    {[...list]
                      .sort((a, b) => a.scheduledStartAt.localeCompare(b.scheduledStartAt))
                      .map((trip) => (
                        <li key={trip.id}>
                          <Link
                            to={`/trips/${trip.id}`}
                            className="flex flex-wrap items-center gap-x-3 gap-y-1 rounded-md px-1 py-2 text-sm hover:bg-brand-50"
                          >
                            <span className="tabular w-16 text-slate-500">
                              {fmtTime(trip.scheduledStartAt)}
                            </span>
                            <span className="min-w-0 flex-1 truncate font-medium text-slate-900">
                              {trip.to
                                ? t('common.route', { from: trip.from.text, to: trip.to.text })
                                : trip.from.text}
                            </span>
                            <span className="text-slate-600">
                              {trip.driver?.name ?? t('common.unassigned')}
                            </span>
                            <TripStatusBadge status={trip.status} />
                          </Link>
                        </li>
                      ))}
                  </ul>
                )}
              </>
            )}
          </QueryState>
        </Card>

        <div className="space-y-4">
          <Card title={t('dashboard.needsAttention')}>
            <QueryState query={summary}>
              {(s) => (
                <dl className="grid grid-cols-2 gap-3 text-center">
                  <Link to="/alerts" className="rounded-md bg-red-50 p-3 hover:bg-red-100">
                    <dd className="tabular text-2xl font-semibold text-red-700">
                      {s.openAlerts.critical}
                    </dd>
                    <dt className="text-xs text-red-800">{t('dashboard.criticalAlerts')}</dt>
                  </Link>
                  <Link to="/review" className="rounded-md bg-brand-50 p-3 hover:bg-brand-100">
                    <dd className="tabular text-2xl font-semibold text-brand-800">
                      {s.openReviewItems}
                    </dd>
                    <dt className="text-xs text-brand-700">{t('dashboard.toReview')}</dt>
                  </Link>
                </dl>
              )}
            </QueryState>
          </Card>
          <Card
            title={t('dashboard.documentsDue')}
            actions={
              <Link className="text-sm text-brand-700 hover:underline" to="/documents">
                {t('dashboard.allDocuments')}
              </Link>
            }
          >
            <QueryState query={documents}>
              {(docs) => {
                const due = docs
                  .filter((d) => d.status === 'expiring' || d.status === 'expired')
                  .slice(0, 6);
                return due.length === 0 ? (
                  <EmptyState title={t('dashboard.nothingExpiring')} />
                ) : (
                  <ul className="space-y-2 text-sm">
                    {due.map((d) => (
                      <li key={d.id} className="flex items-center justify-between gap-2">
                        <span>
                          {t(`enums.docType.${d.docType}`)}
                          <span className="block text-xs text-slate-500">
                            {fmtDate(d.expiresOn)}
                          </span>
                        </span>
                        <DocumentStatusBadge doc={d} />
                      </li>
                    ))}
                  </ul>
                );
              }}
            </QueryState>
          </Card>
        </div>

        <Card
          title={t('dashboard.openAlerts')}
          className="lg:col-span-3"
          actions={
            <Link className="text-sm text-brand-700 hover:underline" to="/alerts">
              {t('dashboard.alertsInbox')}
            </Link>
          }
        >
          <QueryState query={alerts}>
            {(list) =>
              list.length === 0 ? (
                <EmptyState title={t('dashboard.noOpenAlerts')} />
              ) : (
                <ul className="divide-y divide-slate-100">
                  {[...list]
                    .sort(
                      (a, b) =>
                        SEVERITY_ORDER[a.severity] - SEVERITY_ORDER[b.severity] ||
                        b.createdAt.localeCompare(a.createdAt),
                    )
                    .slice(0, 6)
                    .map((a) => {
                      const text = alertText(a);
                      return (
                        <li key={a.id} className="flex flex-wrap items-start gap-3 py-2.5 text-sm">
                          <SeverityBadge severity={a.severity} />
                          <div className="min-w-0 flex-1">
                            <p className="font-medium text-slate-900">{text.title}</p>
                            <p className="line-clamp-2 text-slate-600">{text.explanation}</p>
                          </div>
                          <span className="text-xs text-slate-500">{fmtDateTime(a.createdAt)}</span>
                        </li>
                      );
                    })}
                </ul>
              )
            }
          </QueryState>
        </Card>
      </div>
    </>
  );
}
