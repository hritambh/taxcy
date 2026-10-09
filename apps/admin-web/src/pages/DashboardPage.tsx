import { Link } from 'react-router';
import { DocumentStatusBadge, SeverityBadge, TripStatusBadge } from '../components/status.js';
import { DOC_NAMES } from '../lib/labels.js';
import { Card, EmptyState, PageHeader, QueryState } from '../components/ui.js';
import type { Alert, TripStatus } from '../lib/api-types.js';
import { fmtDate, fmtDateTime, fmtTime, istDayRange, istToday } from '../lib/format.js';
import { useAlerts, useAlertSummary, useDocuments, useTrips } from '../lib/queries.js';

const SEVERITY_ORDER: Record<Alert['severity'], number> = { critical: 0, warning: 1, info: 2 };
const STATUSES: TripStatus[] = ['created', 'assigned', 'started', 'ended', 'settled', 'cancelled'];

export function DashboardPage() {
  const today = istToday();
  const trips = useTrips({ ...istDayRange(today), limit: 200 });
  const alerts = useAlerts({ status: 'open', limit: 100 });
  const summary = useAlertSummary();
  const documents = useDocuments({ expiringWithinDays: 30 });

  return (
    <>
      <PageHeader title="Today" description={fmtDate(today)} />
      <div className="grid gap-4 lg:grid-cols-3">
        <Card
          title="Today’s trips"
          className="lg:col-span-2"
          actions={
            <Link className="text-sm text-brand-700 hover:underline" to="/trips">
              All trips
            </Link>
          }
        >
          <QueryState query={trips}>
            {(list) => (
              <>
                <dl className="mb-4 grid grid-cols-3 gap-3 sm:grid-cols-6">
                  {STATUSES.map((status) => (
                    <div key={status} className="rounded-md bg-slate-50 p-2 text-center">
                      <dd className="tabular text-xl font-semibold text-slate-900">
                        {list.filter((t) => t.status === status).length}
                      </dd>
                      <dt className="text-xs text-slate-500 capitalize">{status}</dt>
                    </div>
                  ))}
                </dl>
                {list.length === 0 ? (
                  <EmptyState title="No trips scheduled today" />
                ) : (
                  <ul className="divide-y divide-slate-100">
                    {[...list]
                      .sort((a, b) => a.scheduledStartAt.localeCompare(b.scheduledStartAt))
                      .map((trip) => (
                        <li key={trip.id}>
                          <Link
                            to={`/trips/${trip.id}`}
                            className="flex flex-wrap items-center gap-x-3 gap-y-1 py-2 text-sm hover:bg-slate-50"
                          >
                            <span className="tabular w-16 text-slate-500">
                              {fmtTime(trip.scheduledStartAt)}
                            </span>
                            <span className="min-w-0 flex-1 truncate font-medium text-slate-900">
                              {trip.from.text}
                              {trip.to ? ` → ${trip.to.text}` : ''}
                            </span>
                            <span className="text-slate-600">
                              {trip.driver?.name ?? 'Unassigned'}
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
          <Card title="Needs your attention">
            <QueryState query={summary}>
              {(s) => (
                <dl className="grid grid-cols-2 gap-3 text-center">
                  <Link to="/alerts" className="rounded-md bg-red-50 p-3 hover:bg-red-100">
                    <dd className="tabular text-2xl font-semibold text-red-700">
                      {s.openAlerts.critical}
                    </dd>
                    <dt className="text-xs text-red-800">Critical alerts</dt>
                  </Link>
                  <Link to="/review" className="rounded-md bg-slate-50 p-3 hover:bg-slate-100">
                    <dd className="tabular text-2xl font-semibold text-slate-900">
                      {s.openReviewItems}
                    </dd>
                    <dt className="text-xs text-slate-600">To review</dt>
                  </Link>
                </dl>
              )}
            </QueryState>
          </Card>
          <Card
            title="Documents due soon"
            actions={
              <Link className="text-sm text-brand-700 hover:underline" to="/documents">
                All
              </Link>
            }
          >
            <QueryState query={documents}>
              {(docs) => {
                const due = docs
                  .filter((d) => d.status === 'expiring' || d.status === 'expired')
                  .slice(0, 6);
                return due.length === 0 ? (
                  <EmptyState title="Nothing expiring in the next 30 days" />
                ) : (
                  <ul className="space-y-2 text-sm">
                    {due.map((d) => (
                      <li key={d.id} className="flex items-center justify-between gap-2">
                        <span>
                          {DOC_NAMES[d.docType]}
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
          title="Open alerts"
          className="lg:col-span-3"
          actions={
            <Link className="text-sm text-brand-700 hover:underline" to="/alerts">
              Alerts inbox
            </Link>
          }
        >
          <QueryState query={alerts}>
            {(list) =>
              list.length === 0 ? (
                <EmptyState title="No open alerts" />
              ) : (
                <ul className="divide-y divide-slate-100">
                  {[...list]
                    .sort(
                      (a, b) =>
                        SEVERITY_ORDER[a.severity] - SEVERITY_ORDER[b.severity] ||
                        b.createdAt.localeCompare(a.createdAt),
                    )
                    .slice(0, 6)
                    .map((a) => (
                      <li key={a.id} className="flex flex-wrap items-start gap-3 py-2.5 text-sm">
                        <SeverityBadge severity={a.severity} />
                        <div className="min-w-0 flex-1">
                          <p className="font-medium text-slate-900">{a.title}</p>
                          <p className="line-clamp-2 text-slate-600">{a.explanation}</p>
                        </div>
                        <span className="text-xs text-slate-500">{fmtDateTime(a.createdAt)}</span>
                      </li>
                    ))}
                </ul>
              )
            }
          </QueryState>
        </Card>
      </div>
    </>
  );
}
