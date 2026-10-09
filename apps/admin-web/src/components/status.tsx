import type { Alert, DocumentRow, TripStatus } from '../lib/api-types.js';
import { humanize } from '../lib/format.js';
import { Badge, type Tone } from './ui.js';

const TRIP_TONES: Record<TripStatus, Tone> = {
  created: 'neutral',
  assigned: 'info',
  started: 'brand',
  ended: 'success',
  settled: 'success',
  cancelled: 'danger',
};

export function TripStatusBadge({ status }: { status: TripStatus }) {
  return <Badge tone={TRIP_TONES[status]}>{humanize(status)}</Badge>;
}

const SEVERITY_TONES: Record<Alert['severity'], Tone> = {
  info: 'info',
  warning: 'warning',
  critical: 'danger',
};

export function SeverityBadge({ severity }: { severity: Alert['severity'] }) {
  return <Badge tone={SEVERITY_TONES[severity]}>{humanize(severity)}</Badge>;
}

const DOC_TONES: Record<DocumentRow['status'], Tone> = {
  valid: 'success',
  expiring: 'warning',
  expired: 'danger',
  superseded: 'neutral',
};

export function DocumentStatusBadge({ doc }: { doc: Pick<DocumentRow, 'status' | 'daysLeft'> }) {
  const text =
    doc.status === 'expired'
      ? `Expired ${String(-doc.daysLeft)}d ago`
      : doc.status === 'expiring'
        ? doc.daysLeft === 0
          ? 'Expires today'
          : `Expires in ${String(doc.daysLeft)}d`
        : humanize(doc.status);
  return <Badge tone={DOC_TONES[doc.status]}>{text}</Badge>;
}
