import { Injectable } from '@nestjs/common';
import type { Prisma, TenantTx } from '@taxcy/db';
import { newId } from '../../platform/ids.js';

export type ReviewKind =
  | 'ocr_mismatch_odometer'
  | 'ocr_mismatch_receipt'
  | 'odometer_regression'
  | 'implausible_efficiency'
  | 'mock_location'
  | 'orphan_evidence'
  | 'clock_skew'
  | 'upload_mismatch';

export interface RaiseReview {
  kind: ReviewKind;
  subjectType: string;
  subjectId: string;
  mediaId?: string | null;
  typedValue?: string | null;
  ocrValue?: string | null;
  context?: Prisma.InputJsonValue;
}

@Injectable()
export class ReviewItemsRepository {
  /**
   * Raises a review item once per (kind, subject). Re-raising an open item refreshes
   * its values (e.g. OCR re-ran); a resolved item stays resolved.
   */
  async raise(tx: TenantTx, item: RaiseReview): Promise<void> {
    const values = {
      mediaId: item.mediaId ?? null,
      typedValue: item.typedValue ?? null,
      ocrValue: item.ocrValue ?? null,
      context: item.context ?? {},
    };
    const existing = await tx.reviewItem.findUnique({
      where: {
        kind_subjectType_subjectId: {
          kind: item.kind,
          subjectType: item.subjectType,
          subjectId: item.subjectId,
        },
      },
      select: { id: true, status: true },
    });
    if (!existing) {
      await tx.reviewItem.create({
        data: {
          id: newId(),
          orgId: tx.orgId,
          kind: item.kind,
          subjectType: item.subjectType,
          subjectId: item.subjectId,
          ...values,
        },
      });
    } else if (existing.status === 'open') {
      await tx.reviewItem.update({ where: { id: existing.id }, data: values });
    }
  }

  /** Closes an open item that no longer applies (e.g. the values now agree). */
  async autoResolve(
    tx: TenantTx,
    kind: ReviewKind,
    subjectType: string,
    subjectId: string,
  ): Promise<void> {
    await tx.reviewItem.updateMany({
      where: { orgId: tx.orgId, kind, subjectType, subjectId, status: 'open' },
      data: {
        status: 'dismissed',
        resolvedAt: new Date(),
        resolution: { auto: true, reason: 'values now agree' },
      },
    });
  }
}
