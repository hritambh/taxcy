import {
  GetObjectCommand,
  HeadObjectCommand,
  NotFound,
  PutObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Inject, Injectable } from '@nestjs/common';
import type { GeoPoint, MediaKind } from '@taxcy/contracts';
import type { TenantTx } from '@taxcy/db';
import { createHash } from 'node:crypto';
import type { Readable } from 'node:stream';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { APP_CONFIG, type AppConfig } from '../../platform/config.js';
import { AppError, notFound } from '../../platform/errors.js';
import { publish } from '../../platform/outbox.js';
import { Db } from '../../platform/prisma.service.js';
import { S3Service } from '../../platform/s3.service.js';
import { ReviewItemsRepository } from '../alerts/review-items.repository.js';
import { MediaRepository, type MediaRow } from './media.repository.js';

const EXTENSIONS: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'application/pdf': 'pdf',
};

export interface CreateMediaInput {
  id: string;
  kind: MediaKind;
  contentType: string;
  sha256: string;
  byteSize: number;
  capturedAt: Date;
  location?: (GeoPoint & { accuracyM?: number | undefined }) | undefined;
  isMockLocation?: boolean | undefined;
  deviceId?: string | undefined;
}

export interface UploadTicket extends Pick<
  MediaRow,
  'id' | 'kind' | 'status' | 'contentType' | 'capturedAt' | 'uploadedAt'
> {
  uploadUrl: string | null;
  uploadHeaders: Record<string, string>;
  uploadUrlExpiresAt: Date | null;
}

@Injectable()
export class MediaService {
  constructor(
    @Inject(APP_CONFIG) private readonly config: AppConfig,
    private readonly db: Db,
    private readonly s3: S3Service,
    private readonly media: MediaRepository,
    private readonly reviews: ReviewItemsRepository,
  ) {}

  /** Idempotent on the client's id: a retry gets a fresh URL for the same object. */
  async create(auth: TenantAuth, input: CreateMediaInput): Promise<UploadTicket> {
    const row = await this.db.tenant(auth.orgId, async (tx) => {
      const existing = await this.media.find(tx, input.id);
      if (existing) {
        if (existing.sha256 !== input.sha256 || existing.kind !== input.kind) {
          throw new AppError(
            'IDEMPOTENCY_CONFLICT',
            'This media id was already registered with different content',
          );
        }
        return existing;
      }
      const month = input.capturedAt.toISOString().slice(0, 7).replace('-', '/');
      await this.media.insert(tx, {
        id: input.id,
        kind: input.kind,
        contentType: input.contentType,
        sha256: input.sha256,
        byteSize: input.byteSize,
        capturedAt: input.capturedAt,
        uploadedBy: auth.userId,
        storageKey: `${auth.orgId}/${input.kind}/${month}/${input.id}.${EXTENSIONS[input.contentType] ?? 'bin'}`,
        location: input.location,
        isMockLocation: input.isMockLocation,
        deviceId: input.deviceId,
      });
      if (input.isMockLocation) {
        await this.reviews.raise(tx, {
          kind: 'mock_location',
          subjectType: 'media',
          subjectId: input.id,
          mediaId: input.id,
          context: {
            reason: 'Photo was captured while the phone reported a mock (fake) GPS location',
          },
        });
      }
      const created = await this.media.find(tx, input.id);
      if (!created) throw new Error('media insert failed');
      return created;
    });
    return this.ticket(row);
  }

  /** Verifies the uploaded bytes against the declared size and SHA-256, then queues OCR. */
  async complete(auth: TenantAuth, id: string): Promise<MediaRow> {
    const row = await this.db.tenant(auth.orgId, (tx) => this.media.find(tx, id));
    if (!row) throw notFound('Media');
    if (row.status !== 'pending') return row;

    let actual: { sha256: string; size: number };
    try {
      await this.s3.client.send(
        new HeadObjectCommand({ Bucket: this.s3.bucket, Key: row.storageKey }),
      );
      actual = await this.digest(row.storageKey);
    } catch (error) {
      if (error instanceof NotFound || (error as { name?: string }).name === 'NoSuchKey') {
        throw new AppError('UPLOAD_NOT_FOUND', 'Nothing has been uploaded for this media id yet');
      }
      throw error;
    }

    if (actual.sha256 !== row.sha256 || (row.byteSize !== null && actual.size !== row.byteSize)) {
      // Record the rejection in its own committed transaction, then fail the request.
      await this.db.tenant(auth.orgId, async (tx) => {
        await this.media.markRejected(tx, id);
        await this.reviews.raise(tx, {
          kind: 'upload_mismatch',
          subjectType: 'media',
          subjectId: id,
          mediaId: id,
          context: { expected: { sha256: row.sha256, size: row.byteSize }, actual },
        });
      });
      throw new AppError(
        'UPLOAD_MISMATCH',
        'Uploaded file does not match the declared checksum or size',
        {
          expectedSha256: row.sha256,
          actualSha256: actual.sha256,
        },
      );
    }

    return this.db.tenant(auth.orgId, async (tx) => {
      await this.media.markUploaded(tx, id);
      await publish(tx, 'media.uploaded', { mediaId: id });
      return this.requireRow(tx, id);
    });
  }

  async viewUrl(auth: TenantAuth, id: string): Promise<{ url: string; expiresAt: Date }> {
    const row = await this.db.tenant(auth.orgId, (tx) => this.media.find(tx, id));
    if (row?.status !== 'uploaded') throw notFound('Media');
    const expiresIn = 300;
    const url = await getSignedUrl(
      this.s3.publicClient,
      new GetObjectCommand({ Bucket: this.s3.bucket, Key: row.storageKey }),
      { expiresIn },
    );
    return { url, expiresAt: new Date(Date.now() + expiresIn * 1000) };
  }

  private async ticket(row: MediaRow): Promise<UploadTicket> {
    const base = {
      id: row.id,
      kind: row.kind,
      status: row.status,
      contentType: row.contentType,
      capturedAt: row.capturedAt,
      uploadedAt: row.uploadedAt,
    };
    if (row.status !== 'pending')
      return { ...base, uploadUrl: null, uploadHeaders: {}, uploadUrlExpiresAt: null };
    const expiresIn = this.config.S3_UPLOAD_URL_TTL_SECONDS;
    const uploadUrl = await getSignedUrl(
      this.s3.publicClient,
      new PutObjectCommand({
        Bucket: this.s3.bucket,
        Key: row.storageKey,
        ContentType: row.contentType,
      }),
      { expiresIn },
    );
    return {
      ...base,
      uploadUrl,
      uploadHeaders: { 'Content-Type': row.contentType },
      uploadUrlExpiresAt: new Date(Date.now() + expiresIn * 1000),
    };
  }

  private async digest(storageKey: string): Promise<{ sha256: string; size: number }> {
    const object = await this.s3.client.send(
      new GetObjectCommand({ Bucket: this.s3.bucket, Key: storageKey }),
    );
    const hash = createHash('sha256');
    let size = 0;
    for await (const chunk of object.Body as Readable) {
      const buffer = chunk as Buffer;
      hash.update(buffer);
      size += buffer.length;
    }
    return { sha256: hash.digest('hex'), size };
  }

  private async requireRow(tx: TenantTx, id: string): Promise<MediaRow> {
    const row = await this.media.find(tx, id);
    if (!row) throw notFound('Media');
    return row;
  }
}
