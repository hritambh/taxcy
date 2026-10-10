import { Injectable } from '@nestjs/common';
import {
  AlertKind,
  AlertMessage,
  AlertStatus,
  ReviewKind,
  ReviewStatus,
  type Alert,
  type ReviewItem,
} from '@taxcy/contracts';
import { z } from 'zod';
import type { Prisma, TenantTx } from '@taxcy/db';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { AppError, notFound } from '../../platform/errors.js';
import { publish } from '../../platform/outbox.js';
import { Db } from '../../platform/prisma.service.js';

const FUEL_ALERTS = new Set(['fuel_efficiency_low', 'fuel_cost_high']);
const asRecord = (v: Prisma.JsonValue | null): Record<string, unknown> =>
  v && typeof v === 'object' && !Array.isArray(v) ? v : {};

const Severity = z.enum(['info', 'warning', 'critical']);

// Rows carry Dates (the response encoder turns them into ISO strings); only the
// string columns that back enums need narrowing.
function toAlert(row: Prisma.AlertGetPayload<object>): Alert {
  return {
    ...row,
    kind: AlertKind.parse(row.kind),
    severity: Severity.parse(row.severity),
    status: AlertStatus.parse(row.status),
    data: asRecord(row.data),
    // Rows written before messages existed (or with an unknown shape) fall back to the text.
    message: AlertMessage.safeParse(row.message).data ?? null,
  };
}

function toReview(row: Prisma.ReviewItemGetPayload<object>): ReviewItem {
  return {
    ...row,
    kind: ReviewKind.parse(row.kind),
    status: ReviewStatus.parse(row.status),
    context: asRecord(row.context),
    resolution: row.resolution === null ? null : asRecord(row.resolution),
  };
}

@Injectable()
export class InboxService {
  constructor(private readonly db: Db) {}

  async alerts(
    auth: TenantAuth,
    q: {
      status?: string | undefined;
      kind?: string | undefined;
      vehicleId?: string | undefined;
      tripId?: string | undefined;
      limit: number;
    },
  ): Promise<Alert[]> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const rows = await tx.alert.findMany({
        where: {
          orgId: tx.orgId,
          ...(q.status ? { status: q.status } : {}),
          ...(q.kind ? { kind: q.kind } : {}),
          ...(q.vehicleId ? { vehicleId: q.vehicleId } : {}),
          ...(q.tripId ? { tripId: q.tripId } : {}),
        },
        orderBy: { createdAt: 'desc' },
        take: q.limit,
      });
      return rows.map(toAlert);
    });
  }

  async summary(auth: TenantAuth) {
    return this.db.tenant(auth.orgId, async (tx) => {
      const [bySeverity, openReviewItems] = await Promise.all([
        tx.alert.groupBy({
          by: ['severity'],
          where: { orgId: tx.orgId, status: 'open' },
          _count: { _all: true },
        }),
        tx.reviewItem.count({ where: { orgId: tx.orgId, status: 'open' } }),
      ]);
      const count = (s: string) => bySeverity.find((r) => r.severity === s)?._count._all ?? 0;
      return {
        openAlerts: { info: count('info'), warning: count('warning'), critical: count('critical') },
        openReviewItems,
      };
    });
  }

  async updateAlert(
    auth: TenantAuth,
    id: string,
    input: {
      status: 'acknowledged' | 'resolved' | 'dismissed';
      falsePositive?: boolean | undefined;
    },
  ): Promise<Alert> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const alert = await tx.alert.findFirst({ where: { id, orgId: tx.orgId } });
      if (!alert) throw notFound('Alert');
      const closing = input.status !== 'acknowledged';
      const updated = await tx.alert.update({
        where: { id },
        data: {
          status: input.status,
          resolvedBy: closing ? auth.userId : null,
          resolvedAt: closing ? new Date() : null,
          ...(input.falsePositive === undefined
            ? {}
            : {
                data: {
                  ...asRecord(alert.data),
                  falsePositive: input.falsePositive,
                },
              }),
        },
      });
      // A dismissed false alarm lets that cycle train the vehicle's baseline.
      if (FUEL_ALERTS.has(alert.kind) && input.falsePositive && alert.vehicleId) {
        await publish(tx, 'fuel.recompute', { vehicleId: alert.vehicleId });
      }
      return toAlert(updated);
    });
  }

  async reviewItems(
    auth: TenantAuth,
    q: { status?: string | undefined; limit: number },
  ): Promise<ReviewItem[]> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const rows = await tx.reviewItem.findMany({
        where: { orgId: tx.orgId, ...(q.status ? { status: q.status } : {}) },
        orderBy: { createdAt: 'asc' },
        take: q.limit,
      });
      return rows.map(toReview);
    });
  }

  /**
   * Applies a reviewer's decision. Taking the OCR value or a correction rewrites the
   * odometer reading or receipt amount, then re-runs whatever depends on it (the
   * vehicle's fuel audit, the trip's distance check).
   */
  async resolveReview(
    auth: TenantAuth,
    id: string,
    input: {
      resolution: 'accepted_typed' | 'accepted_ocr' | 'corrected' | 'dismissed';
      correctedValue?: number | undefined;
      note?: string | undefined;
    },
  ): Promise<ReviewItem> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const item = await tx.reviewItem.findFirst({ where: { id, orgId: tx.orgId } });
      if (!item) throw notFound('Review item');
      if (item.status !== 'open')
        throw new AppError('CONFLICT', 'This item has already been decided');
      const rewrites = input.resolution === 'accepted_ocr' || input.resolution === 'corrected';
      let applied: number | null = null;
      if (rewrites) {
        applied =
          input.resolution === 'corrected'
            ? (input.correctedValue ?? null)
            : item.ocrValue === null
              ? null
              : Number(item.ocrValue);
        if (applied === null || Number.isNaN(applied)) {
          throw new AppError(
            'VALIDATION_FAILED',
            input.resolution === 'corrected'
              ? 'Send correctedValue'
              : 'There is no OCR value to accept',
          );
        }
        await this.applyValue(tx, item.subjectType, item.subjectId, applied);
      }
      const updated = await tx.reviewItem.update({
        where: { id },
        data: {
          status: input.resolution,
          resolvedBy: auth.userId,
          resolvedAt: new Date(),
          resolution: {
            ...(applied === null ? {} : { appliedValue: applied }),
            ...(input.note ? { note: input.note } : {}),
          },
        },
      });
      return toReview(updated);
    });
  }

  private async applyValue(
    tx: TenantTx,
    subjectType: string,
    subjectId: string,
    value: number,
  ): Promise<void> {
    if (subjectType === 'odometer_reading') {
      const reading = await tx.odometerReading.update({
        where: { id: subjectId },
        data: { typedKm: value },
      });
      const fill = await tx.fuelFill.findFirst({
        where: { odometerId: reading.id, orgId: tx.orgId },
        select: { vehicleId: true },
      });
      if (fill) await publish(tx, 'fuel.recompute', { vehicleId: fill.vehicleId });
      const trip = await tx.trip.findFirst({
        where: {
          orgId: tx.orgId,
          OR: [{ startOdometerId: reading.id }, { endOdometerId: reading.id }],
        },
        select: { id: true, endOdometerId: true },
      });
      if (trip?.endOdometerId) await publish(tx, 'trip.closed', { tripId: trip.id });
      return;
    }
    if (subjectType === 'fuel_fill') {
      const fill = await tx.fuelFill.update({
        where: { id: subjectId },
        data: { costPaise: BigInt(value) },
      });
      await publish(tx, 'fuel.recompute', { vehicleId: fill.vehicleId });
      return;
    }
    throw new AppError(
      'VALIDATION_FAILED',
      'This kind of item has no value to correct; accept or dismiss it',
    );
  }
}
