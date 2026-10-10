import { Injectable } from '@nestjs/common';
import type { Document, DocType } from '@taxcy/contracts';
import type { Prisma, TenantTx } from '@taxcy/db';
import {
  daysUntil,
  expiryBucket,
  expirySeverity,
  explainExpiry,
  istBusinessDate,
} from '@taxcy/domain';
import { AppError, notFound } from '../../platform/errors.js';
import { newId } from '../../platform/ids.js';
import { AlertsRepository } from '../alerts/alerts.repository.js';
import { SettingsService } from './settings.service.js';

type DocumentRow = Prisma.DocumentGetPayload<object>;

const isoDate = (d: Date) => d.toISOString().slice(0, 10);
const dedupePrefix = (docId: string) => `doc:${docId}:`;

export interface DocumentDetails {
  number?: string | undefined;
  validFrom?: Date | undefined;
  expiresOn: Date;
  mediaId?: string | undefined;
}

@Injectable()
export class DocumentsService {
  constructor(
    private readonly alerts: AlertsRepository,
    private readonly settings: SettingsService,
  ) {}

  async list(
    tx: TenantTx,
    filter: {
      vehicleId?: string | undefined;
      driverId?: string | undefined;
      expiringWithinDays?: number | undefined;
      includeSuperseded?: boolean | undefined;
    },
  ): Promise<Document[]> {
    const { audit } = await this.settings.get(tx);
    const today = istBusinessDate(new Date());
    const rows = await tx.document.findMany({
      where: {
        orgId: tx.orgId,
        ...(filter.vehicleId ? { vehicleId: filter.vehicleId } : {}),
        ...(filter.driverId ? { driverId: filter.driverId } : {}),
        ...(filter.includeSuperseded ? {} : { supersededBy: null }),
        ...(filter.expiringWithinDays === undefined
          ? {}
          : {
              expiresOn: {
                lte: new Date(
                  Date.parse(`${today}T00:00:00Z`) + filter.expiringWithinDays * 86_400_000,
                ),
              },
            }),
      },
      orderBy: [{ expiresOn: 'asc' }],
    });
    return rows.map((r) => this.toDocument(r, today, audit.docAlertDays));
  }

  async create(
    tx: TenantTx,
    input: DocumentDetails & {
      docType: DocType;
      vehicleId?: string | undefined;
      driverId?: string | undefined;
    },
  ): Promise<Document> {
    if (Boolean(input.vehicleId) === Boolean(input.driverId)) {
      throw new AppError(
        'VALIDATION_FAILED',
        'A document belongs to exactly one vehicle or one driver',
      );
    }
    if ((input.docType === 'driving_licence') !== Boolean(input.driverId)) {
      throw new AppError(
        'VALIDATION_FAILED',
        'Driving licences belong to drivers; RC, insurance, permit and PUC to vehicles',
      );
    }
    if (
      input.vehicleId &&
      !(await tx.vehicle.count({ where: { id: input.vehicleId, orgId: tx.orgId } }))
    ) {
      throw notFound('Vehicle');
    }
    if (
      input.driverId &&
      !(await tx.driver.count({ where: { id: input.driverId, orgId: tx.orgId } }))
    ) {
      throw notFound('Driver');
    }
    await this.assertMedia(tx, input.mediaId);
    const row = await tx.document.create({
      data: {
        id: newId(),
        orgId: tx.orgId,
        docType: input.docType,
        vehicleId: input.vehicleId ?? null,
        driverId: input.driverId ?? null,
        number: input.number ?? null,
        validFrom: input.validFrom ?? null,
        expiresOn: input.expiresOn,
        mediaId: input.mediaId ?? null,
      },
    });
    await this.evaluateAlerts(tx, row);
    return this.present(tx, row);
  }

  /** The renewed copy replaces the old one; the old one's alerts are resolved. */
  async renew(tx: TenantTx, id: string, input: DocumentDetails): Promise<Document> {
    const old = await tx.document.findFirst({ where: { id, orgId: tx.orgId } });
    if (!old) throw notFound('Document');
    if (old.supersededBy) throw new AppError('CONFLICT', 'This document has already been renewed');
    await this.assertMedia(tx, input.mediaId);
    const row = await tx.document.create({
      data: {
        id: newId(),
        orgId: tx.orgId,
        docType: old.docType,
        vehicleId: old.vehicleId,
        driverId: old.driverId,
        number: input.number ?? old.number,
        validFrom: input.validFrom ?? null,
        expiresOn: input.expiresOn,
        mediaId: input.mediaId ?? null,
      },
    });
    await tx.document.update({ where: { id: old.id }, data: { supersededBy: row.id } });
    await this.alerts.autoResolvePrefix(tx, dedupePrefix(old.id));
    await this.evaluateAlerts(tx, row);
    return this.present(tx, row);
  }

  /**
   * Raises the alert for the document's current expiry bucket (30/7/1 days ahead, or
   * expired) and resolves alerts for earlier buckets, so only the latest shows.
   */
  async evaluateAlerts(
    tx: TenantTx,
    doc: DocumentRow,
    today = istBusinessDate(new Date()),
  ): Promise<void> {
    if (doc.supersededBy) return;
    const { audit } = await this.settings.get(tx);
    const expiresOn = isoDate(doc.expiresOn);
    const bucket = expiryBucket(expiresOn, today, audit.docAlertDays);
    if (bucket === null) {
      await this.alerts.autoResolvePrefix(tx, dedupePrefix(doc.id));
      return;
    }
    const dedupeKey = `${dedupePrefix(doc.id)}${String(bucket)}`;
    const text = explainExpiry({
      docType: doc.docType,
      subject: await this.subjectLabel(tx, doc),
      subjectKind: doc.vehicleId ? 'vehicle' : 'driver',
      expiresOn,
      today,
    });
    await this.alerts.raise(tx, {
      kind: bucket === 'expired' ? 'document_expired' : 'document_expiring',
      severity: expirySeverity(bucket),
      ...text,
      subjectType: 'document',
      subjectId: doc.id,
      vehicleId: doc.vehicleId,
      driverId: doc.driverId,
      data: { docType: doc.docType, expiresOn, bucket },
      dedupeKey,
    });
    await this.alerts.autoResolvePrefix(tx, dedupePrefix(doc.id), dedupeKey);
  }

  private async subjectLabel(tx: TenantTx, doc: DocumentRow): Promise<string> {
    if (doc.vehicleId) {
      const v = await tx.vehicle.findUnique({
        where: { id: doc.vehicleId },
        select: { registrationNo: true },
      });
      return v?.registrationNo ?? 'vehicle';
    }
    const d = doc.driverId
      ? await tx.driver.findUnique({ where: { id: doc.driverId }, select: { name: true } })
      : null;
    return d?.name ?? 'driver';
  }

  private async assertMedia(tx: TenantTx, mediaId: string | undefined): Promise<void> {
    if (mediaId && !(await tx.mediaObject.count({ where: { id: mediaId, orgId: tx.orgId } })))
      throw notFound('Media');
  }

  private async present(tx: TenantTx, row: DocumentRow): Promise<Document> {
    const { audit } = await this.settings.get(tx);
    return this.toDocument(row, istBusinessDate(new Date()), audit.docAlertDays);
  }

  private toDocument(row: DocumentRow, today: string, alertDays: readonly number[]): Document {
    const daysLeft = daysUntil(isoDate(row.expiresOn), today);
    const status = row.supersededBy
      ? 'superseded'
      : daysLeft < 0
        ? 'expired'
        : daysLeft <= Math.max(...alertDays)
          ? 'expiring'
          : 'valid';
    return {
      id: row.id,
      docType: row.docType,
      vehicleId: row.vehicleId,
      driverId: row.driverId,
      number: row.number,
      validFrom: row.validFrom,
      expiresOn: row.expiresOn,
      mediaId: row.mediaId,
      supersededBy: row.supersededBy,
      daysLeft,
      status,
      createdAt: row.createdAt,
    };
  }
}
