import { Injectable } from '@nestjs/common';
import type { TenantTx } from '@taxcy/db';
import { ReviewItemsRepository } from '../alerts/review-items.repository.js';

/** Max difference between typed and OCR odometer km before a human looks at it. */
const ODOMETER_TOLERANCE_KM = 1;
/** Max difference between typed and OCR receipt amount (₹10). */
const RECEIPT_TOLERANCE_PAISE = 1000;

interface LatestOcr {
  status: string;
  valueNumeric: number | null;
  raw: unknown;
}

/**
 * Compares typed values with OCR results. Called from both directions, because they
 * can arrive in either order: when OCR finishes (the reading may already exist) and
 * when a reading or fill is recorded (OCR may already have run). Never blocks the
 * driver; disagreements become review items.
 */
@Injectable()
export class EvidenceReconciler {
  constructor(private readonly reviews: ReviewItemsRepository) {}

  async reconcileOdometerMedia(tx: TenantTx, mediaId: string): Promise<void> {
    const [ocr, readings] = await Promise.all([
      this.latestOcr(tx, mediaId),
      tx.odometerReading.findMany({
        where: { orgId: tx.orgId, mediaId },
        select: { id: true, typedKm: true },
      }),
    ]);
    if (!ocr) return;
    for (const reading of readings) {
      if (ocr.status === 'unreadable') {
        await this.reviews.raise(tx, {
          kind: 'ocr_mismatch_odometer',
          subjectType: 'odometer_reading',
          subjectId: reading.id,
          mediaId,
          typedValue: String(reading.typedKm),
          ocrValue: null,
          context: { reason: 'The odometer could not be read from the photo' },
        });
        continue;
      }
      if (ocr.status !== 'ok' || ocr.valueNumeric === null) continue;
      const ocrKm = Math.round(ocr.valueNumeric);
      await tx.odometerReading.update({ where: { id: reading.id }, data: { ocrKm } });
      if (Math.abs(ocrKm - reading.typedKm) > ODOMETER_TOLERANCE_KM) {
        await this.reviews.raise(tx, {
          kind: 'ocr_mismatch_odometer',
          subjectType: 'odometer_reading',
          subjectId: reading.id,
          mediaId,
          typedValue: String(reading.typedKm),
          ocrValue: String(ocrKm),
          context: { differenceKm: ocrKm - reading.typedKm },
        });
      } else {
        await this.reviews.autoResolve(tx, 'ocr_mismatch_odometer', 'odometer_reading', reading.id);
      }
    }
  }

  async reconcileReceiptMedia(tx: TenantTx, mediaId: string): Promise<void> {
    const [ocr, fills] = await Promise.all([
      this.latestOcr(tx, mediaId),
      tx.fuelFill.findMany({
        where: { orgId: tx.orgId, receiptMediaId: mediaId },
        select: { id: true, costPaise: true, quantityMilli: true },
      }),
    ]);
    if (!ocr) return;
    for (const fill of fills) {
      if (ocr.status === 'unreadable') {
        await this.reviews.raise(tx, {
          kind: 'ocr_mismatch_receipt',
          subjectType: 'fuel_fill',
          subjectId: fill.id,
          mediaId,
          typedValue: fill.costPaise.toString(),
          context: { reason: 'The receipt could not be read from the photo' },
        });
        continue;
      }
      if (ocr.status !== 'ok') continue;
      const raw = (ocr.raw ?? {}) as { amountPaise?: number; quantityMilli?: number };
      const ocrCost = raw.amountPaise;
      await tx.fuelFill.update({
        where: { id: fill.id },
        data: {
          ocrCostPaise: ocrCost === undefined ? null : BigInt(ocrCost),
          ocrQuantityMilli: raw.quantityMilli ?? null,
        },
      });
      if (
        ocrCost !== undefined &&
        Math.abs(ocrCost - Number(fill.costPaise)) > RECEIPT_TOLERANCE_PAISE
      ) {
        await this.reviews.raise(tx, {
          kind: 'ocr_mismatch_receipt',
          subjectType: 'fuel_fill',
          subjectId: fill.id,
          mediaId,
          typedValue: fill.costPaise.toString(),
          ocrValue: String(ocrCost),
          context: { differencePaise: ocrCost - Number(fill.costPaise) },
        });
      } else if (ocrCost !== undefined) {
        await this.reviews.autoResolve(tx, 'ocr_mismatch_receipt', 'fuel_fill', fill.id);
      }
    }
  }

  private async latestOcr(tx: TenantTx, mediaId: string): Promise<LatestOcr | null> {
    return tx.ocrResult.findFirst({
      where: { orgId: tx.orgId, mediaId },
      orderBy: { createdAt: 'desc' },
      select: { status: true, valueNumeric: true, raw: true },
    });
  }
}
