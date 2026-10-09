import { Injectable } from '@nestjs/common';
import { MediaStatus, type MediaKind } from '@taxcy/contracts';
import type { SystemTx, TenantTx } from '@taxcy/db';

export interface MediaRow {
  id: string;
  orgId: string;
  kind: MediaKind;
  status: MediaStatus;
  contentType: string;
  storageKey: string;
  sha256: string;
  byteSize: number | null;
  capturedAt: Date;
  uploadedAt: Date | null;
  uploadedBy: string;
}

const select = {
  id: true,
  orgId: true,
  kind: true,
  status: true,
  contentType: true,
  storageKey: true,
  sha256: true,
  byteSize: true,
  capturedAt: true,
  uploadedAt: true,
  uploadedBy: true,
} as const;

@Injectable()
export class MediaRepository {
  async find(tx: TenantTx | SystemTx, id: string): Promise<MediaRow | null> {
    const row = await tx.mediaObject.findFirst({
      where: { id, ...('orgId' in tx ? { orgId: tx.orgId } : {}) },
      select,
    });
    return row ? { ...row, status: MediaStatus.parse(row.status) } : null;
  }

  async insert(
    tx: TenantTx,
    media: Omit<MediaRow, 'orgId' | 'status' | 'uploadedAt'> & {
      location: { lat: number; lng: number; accuracyM?: number | undefined } | undefined;
      isMockLocation: boolean | undefined;
      deviceId: string | undefined;
    },
  ): Promise<void> {
    await tx.$executeRaw`
      INSERT INTO media_objects (id, org_id, uploaded_by, kind, storage_key, content_type, byte_size, sha256,
        captured_at, capture_location, capture_accuracy_m, is_mock_location, device_id)
      VALUES (${media.id}::uuid, ${tx.orgId}::uuid, ${media.uploadedBy}::uuid, ${media.kind}::media_kind,
        ${media.storageKey}, ${media.contentType}, ${media.byteSize}, ${media.sha256}, ${media.capturedAt},
        ${media.location ? `SRID=4326;POINT(${media.location.lng} ${media.location.lat})` : null}::geography,
        ${media.location?.accuracyM ?? null}, ${media.isMockLocation ?? null}, ${media.deviceId ?? null}::uuid)
      ON CONFLICT (id) DO NOTHING`;
  }

  async markUploaded(tx: TenantTx, id: string): Promise<void> {
    await tx.mediaObject.updateMany({
      where: { id, orgId: tx.orgId, status: 'pending' },
      data: { status: 'uploaded', uploadedAt: new Date() },
    });
  }

  async markRejected(tx: TenantTx, id: string): Promise<void> {
    await tx.mediaObject.updateMany({
      where: { id, orgId: tx.orgId },
      data: { status: 'rejected' },
    });
  }

  /** Capture metadata used by plausibility checks (mock location, where it was taken). */
  async captureInfo(
    tx: TenantTx | SystemTx,
    id: string,
  ): Promise<{ isMockLocation: boolean | null; lat: number | null; lng: number | null } | null> {
    const rows = await tx.$queryRaw<
      { is_mock_location: boolean | null; lat: number | null; lng: number | null }[]
    >`
      SELECT is_mock_location, ST_Y(capture_location::geometry) AS lat, ST_X(capture_location::geometry) AS lng
      FROM media_objects WHERE id = ${id}::uuid`;
    const row = rows[0];
    return row ? { isMockLocation: row.is_mock_location, lat: row.lat, lng: row.lng } : null;
  }
}
