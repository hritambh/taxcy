import { HeadObjectCommand } from '@aws-sdk/client-s3';
import { Injectable } from '@nestjs/common';
import { S3Service } from '../../platform/s3.service.js';

export type OcrResult<T> =
  | { status: 'ok'; value: T; confidence: number; raw: unknown }
  | { status: 'unreadable'; reason: string }
  | { status: 'error'; reason: string };

export interface ImageRef {
  storageKey: string;
}

export interface OcrProvider {
  readonly name: string;
  readOdometer(image: ImageRef): Promise<OcrResult<{ km: number }>>;
  readFuelReceipt(
    image: ImageRef,
  ): Promise<OcrResult<{ amountPaise?: number; quantityMilli?: number }>>;
}

export const OCR_PROVIDER = Symbol('OCR_PROVIDER');

/**
 * Stand-in until a real OCR provider is chosen. It doesn't look at pixels: it reads
 * the expected result from object metadata (x-amz-meta-ocr-km, -ocr-amount-paise,
 * -ocr-quantity-milli, or -ocr-unreadable), which the seed and tests set when they
 * upload. Without metadata it reports `error`, which is logged but never creates a
 * review item, so local development isn't flooded with fake mismatches.
 */
@Injectable()
export class StubOcrProvider implements OcrProvider {
  readonly name = 'stub';

  constructor(private readonly s3: S3Service) {}

  async readOdometer(image: ImageRef): Promise<OcrResult<{ km: number }>> {
    const meta = await this.metadata(image);
    if (meta['ocr-unreadable']) return { status: 'unreadable', reason: 'stub: marked unreadable' };
    const km = Number(meta['ocr-km']);
    if (!meta['ocr-km'] || !Number.isInteger(km))
      return { status: 'error', reason: 'stub: no ocr-km metadata' };
    return { status: 'ok', value: { km }, confidence: 0.99, raw: meta };
  }

  async readFuelReceipt(
    image: ImageRef,
  ): Promise<OcrResult<{ amountPaise?: number; quantityMilli?: number }>> {
    const meta = await this.metadata(image);
    if (meta['ocr-unreadable']) return { status: 'unreadable', reason: 'stub: marked unreadable' };
    const amount = meta['ocr-amount-paise'];
    const quantity = meta['ocr-quantity-milli'];
    if (!amount && !quantity) return { status: 'error', reason: 'stub: no receipt metadata' };
    return {
      status: 'ok',
      value: {
        ...(amount ? { amountPaise: Number(amount) } : {}),
        ...(quantity ? { quantityMilli: Number(quantity) } : {}),
      },
      confidence: 0.99,
      raw: meta,
    };
  }

  private async metadata(image: ImageRef): Promise<Record<string, string>> {
    const head = await this.s3.client.send(
      new HeadObjectCommand({ Bucket: this.s3.bucket, Key: image.storageKey }),
    );
    return head.Metadata ?? {};
  }
}
