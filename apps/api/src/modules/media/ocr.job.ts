import { Inject, Injectable, Logger } from '@nestjs/common';
import { z } from 'zod';
import { newId } from '../../platform/ids.js';
import { OnJob, type JobEvent } from '../../platform/jobs/on-job.js';
import { Db } from '../../platform/prisma.service.js';
import { EvidenceReconciler } from './evidence.reconciler.js';
import { MediaRepository } from './media.repository.js';
import { OCR_PROVIDER, type OcrProvider, type OcrResult } from './ocr.provider.js';

const Payload = z.object({ mediaId: z.uuid() });

@Injectable()
export class OcrJob {
  private readonly logger = new Logger('OcrJob');

  constructor(
    @Inject(OCR_PROVIDER) private readonly ocr: OcrProvider,
    private readonly db: Db,
    private readonly media: MediaRepository,
    private readonly reconciler: EvidenceReconciler,
  ) {}

  @OnJob('media.uploaded')
  async run(event: JobEvent): Promise<void> {
    const { mediaId } = Payload.parse(event.payload);
    if (!event.orgId) throw new Error('media.uploaded without org');
    const orgId = event.orgId;

    const row = await this.db.tenant(orgId, async (tx) => {
      const media = await this.media.find(tx, mediaId);
      const done = await tx.ocrResult.count({ where: { orgId, mediaId, provider: this.ocr.name } });
      return media && done === 0 ? media : null;
    });
    if (!row || (row.kind !== 'odometer' && row.kind !== 'fuel_receipt')) return;

    // OCR runs outside the transaction: it's slow and may call an external service.
    const result: OcrResult<Record<string, number | undefined>> =
      row.kind === 'odometer'
        ? await this.ocr.readOdometer({ storageKey: row.storageKey })
        : await this.ocr.readFuelReceipt({ storageKey: row.storageKey });
    if (result.status === 'error')
      this.logger.warn(`OCR ${this.ocr.name} failed for ${mediaId}: ${result.reason}`);

    await this.db.tenant(orgId, async (tx) => {
      const value = result.status === 'ok' ? result.value : {};
      await tx.ocrResult.create({
        data: {
          id: newId(),
          orgId,
          mediaId,
          provider: this.ocr.name,
          status: result.status,
          valueNumeric:
            row.kind === 'odometer' ? (value['km'] ?? null) : (value['amountPaise'] ?? null),
          raw: {
            ...value,
            ...(result.status === 'ok' ? {} : { reason: result.reason }),
          },
          confidence: result.status === 'ok' ? result.confidence : null,
        },
      });
      if (row.kind === 'odometer') await this.reconciler.reconcileOdometerMedia(tx, mediaId);
      else await this.reconciler.reconcileReceiptMedia(tx, mediaId);
    });
  }
}
