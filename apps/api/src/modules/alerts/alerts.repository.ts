import { Injectable } from '@nestjs/common';
import type { AlertMessage } from '@taxcy/contracts';
import type { Prisma, TenantTx } from '@taxcy/db';
import { newId } from '../../platform/ids.js';

export type AlertKind =
  | 'fuel_efficiency_low'
  | 'fuel_cost_high'
  | 'odo_gps_mismatch'
  | 'document_expiring'
  | 'document_expired'
  | 'cancellation_requested'
  | 'gps_coverage_low';

export interface RaiseAlert {
  kind: AlertKind;
  severity: 'info' | 'warning' | 'critical';
  /** English fallback for clients that don't know the message key. */
  title: string;
  explanation: string;
  message: AlertMessage;
  subjectType: string;
  subjectId: string;
  vehicleId?: string | null;
  driverId?: string | null;
  tripId?: string | null;
  data?: Prisma.InputJsonValue;
  /** One alert per dedupe key per org; raising again updates an open alert. */
  dedupeKey: string;
}

@Injectable()
export class AlertsRepository {
  async raise(tx: TenantTx, alert: RaiseAlert): Promise<void> {
    const values = {
      kind: alert.kind,
      severity: alert.severity,
      title: alert.title,
      explanation: alert.explanation,
      message: alert.message,
      subjectType: alert.subjectType,
      subjectId: alert.subjectId,
      vehicleId: alert.vehicleId ?? null,
      driverId: alert.driverId ?? null,
      tripId: alert.tripId ?? null,
      data: alert.data ?? {},
    };
    const existing = await tx.alert.findUnique({
      where: { orgId_dedupeKey: { orgId: tx.orgId, dedupeKey: alert.dedupeKey } },
      select: { id: true, status: true },
    });
    if (!existing) {
      await tx.alert.create({
        data: { id: newId(), orgId: tx.orgId, dedupeKey: alert.dedupeKey, ...values },
      });
    } else if (existing.status === 'open' || existing.status === 'acknowledged') {
      await tx.alert.update({ where: { id: existing.id }, data: values });
    }
  }

  /** Resolves an open alert whose condition no longer holds (e.g. a recomputed cycle is now fine). */
  async autoResolve(tx: TenantTx, dedupeKey: string): Promise<void> {
    await tx.alert.updateMany({
      where: { orgId: tx.orgId, dedupeKey, status: { in: ['open', 'acknowledged'] } },
      data: { status: 'resolved', resolvedAt: new Date() },
    });
  }

  /** Resolves every open alert whose dedupe key starts with `prefix` (e.g. all alerts for a renewed document). */
  async autoResolvePrefix(tx: TenantTx, prefix: string, exceptKey?: string): Promise<void> {
    await tx.alert.updateMany({
      where: {
        orgId: tx.orgId,
        dedupeKey: { startsWith: prefix, ...(exceptKey ? { not: exceptKey } : {}) },
        status: { in: ['open', 'acknowledged'] },
      },
      data: { status: 'resolved', resolvedAt: new Date() },
    });
  }
}
