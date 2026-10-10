import { useTranslation } from 'react-i18next';
import type { Alert, DocumentRow, TripStatus } from '../lib/api-types.js';
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
  const { t } = useTranslation();
  return <Badge tone={TRIP_TONES[status]}>{t(`enums.tripStatus.${status}`)}</Badge>;
}

const SEVERITY_TONES: Record<Alert['severity'], Tone> = {
  info: 'info',
  warning: 'warning',
  critical: 'danger',
};

export function SeverityBadge({ severity }: { severity: Alert['severity'] }) {
  const { t } = useTranslation();
  return <Badge tone={SEVERITY_TONES[severity]}>{t(`enums.severity.${severity}`)}</Badge>;
}

const DOC_TONES: Record<DocumentRow['status'], Tone> = {
  valid: 'success',
  expiring: 'warning',
  expired: 'danger',
  superseded: 'neutral',
};

export function DocumentStatusBadge({ doc }: { doc: Pick<DocumentRow, 'status' | 'daysLeft'> }) {
  const { t } = useTranslation();
  const text =
    doc.status === 'expired'
      ? t('docStatus.expiredAgo', { count: -doc.daysLeft })
      : doc.status === 'expiring'
        ? doc.daysLeft === 0
          ? t('docStatus.expiresToday')
          : t('docStatus.expiresIn', { count: doc.daysLeft })
        : t(`enums.docStatus.${doc.status}`);
  return <Badge tone={DOC_TONES[doc.status]}>{text}</Badge>;
}
