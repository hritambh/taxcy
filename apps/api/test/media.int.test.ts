import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import type { Session } from '@taxcy/contracts';
import { createHash, randomUUID } from 'node:crypto';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  bearer,
  ownerSession,
  requireEnv,
  runJobs,
  startHarness,
  type Harness,
} from './harness.js';

let h: Harness;
let owner: Session;

const sha256 = (bytes: Buffer) => createHash('sha256').update(bytes).digest('hex');
const photo = (label: string) => Buffer.from(`fake-jpeg-bytes:${label}:${randomUUID()}`);

interface Ticket {
  id: string;
  status: string;
  uploadUrl: string | null;
  uploadHeaders: Record<string, string>;
}

async function register(
  bytes: Buffer,
  extra: Record<string, unknown> = {},
  id: string = randomUUID(),
): Promise<Ticket> {
  const res = await request(h.http)
    .post('/v1/media')
    .set(...bearer(owner))
    .send({
      id,
      kind: 'odometer',
      contentType: 'image/jpeg',
      sha256: sha256(bytes),
      byteSize: bytes.length,
      capturedAt: new Date().toISOString(),
      location: { lat: 18.5204, lng: 73.8567, accuracyM: 8 },
      ...extra,
    })
    .expect(201);
  return res.body as Ticket;
}

async function putTo(ticket: Ticket, bytes: Buffer): Promise<void> {
  if (!ticket.uploadUrl) throw new Error('no upload url');
  const res = await fetch(ticket.uploadUrl, {
    method: 'PUT',
    headers: ticket.uploadHeaders,
    body: bytes,
  });
  expect(res.status).toBe(200);
}

/** Uploads directly with S3 metadata, which the stub OCR provider reads its "result" from. */
async function putWithOcrMetadata(
  orgId: string,
  id: string,
  bytes: Buffer,
  metadata: Record<string, string>,
) {
  const month = new Date().toISOString().slice(0, 7).replace('-', '/');
  const s3 = new S3Client({
    endpoint: requireEnv('S3_ENDPOINT'),
    region: 'ap-south-1',
    forcePathStyle: true,
    credentials: {
      accessKeyId: requireEnv('S3_ACCESS_KEY_ID'),
      secretAccessKey: requireEnv('S3_SECRET_ACCESS_KEY'),
    },
  });
  await s3.send(
    new PutObjectCommand({
      Bucket: 'taxcy-media',
      Key: `${orgId}/odometer/${month}/${id}.jpg`,
      Body: bytes,
      ContentType: 'image/jpeg',
      Metadata: metadata,
    }),
  );
}

beforeAll(async () => {
  h = await startHarness();
  owner = await ownerSession(h);
});

afterAll(async () => {
  await h.close();
});

describe('signed uploads', () => {
  it('registers, uploads via the signed URL, verifies and queues OCR', async () => {
    const bytes = photo('happy');
    const ticket = await register(bytes);
    expect(ticket.status).toBe('pending');
    expect(ticket.uploadUrl).toMatch(/^http/);

    await putTo(ticket, bytes);
    const done = await request(h.http)
      .post(`/v1/media/${ticket.id}/complete`)
      .set(...bearer(owner))
      .expect(200);
    expect(done.body).toMatchObject({ id: ticket.id, status: 'uploaded' });

    const outbox = await h.owner.outboxEvent.findMany({
      where: { topic: 'media.uploaded', dispatchedAt: null },
    });
    expect(outbox.map((e) => (e.payload as { mediaId: string }).mediaId)).toContain(ticket.id);

    const view = await request(h.http)
      .get(`/v1/media/${ticket.id}/url`)
      .set(...bearer(owner))
      .expect(200);
    const fetched = await fetch((view.body as { url: string }).url);
    expect(Buffer.from(await fetched.arrayBuffer())).toEqual(bytes);
  });

  it('is idempotent on the client id, and rejects the same id with different content', async () => {
    const bytes = photo('idem');
    const id = randomUUID();
    await register(bytes, {}, id);
    const again = await register(bytes, {}, id);
    expect(again.id).toBe(id);
    const conflict = await request(h.http)
      .post('/v1/media')
      .set(...bearer(owner))
      .send({
        id,
        kind: 'odometer',
        contentType: 'image/jpeg',
        sha256: sha256(photo('other')),
        byteSize: 10,
        capturedAt: new Date().toISOString(),
      })
      .expect(409);
    expect(conflict.body).toMatchObject({ error: { code: 'IDEMPOTENCY_CONFLICT' } });
  });

  it('refuses to complete before anything is uploaded', async () => {
    const ticket = await register(photo('missing'));
    const res = await request(h.http)
      .post(`/v1/media/${ticket.id}/complete`)
      .set(...bearer(owner))
      .expect(422);
    expect(res.body).toMatchObject({ error: { code: 'UPLOAD_NOT_FOUND' } });
  });

  it('rejects an upload whose bytes do not match the declared checksum', async () => {
    const declared = photo('declared');
    const ticket = await register(declared);
    await putTo(ticket, Buffer.concat([declared, Buffer.from('tampered')]));
    const res = await request(h.http)
      .post(`/v1/media/${ticket.id}/complete`)
      .set(...bearer(owner))
      .expect(422);
    expect(res.body).toMatchObject({ error: { code: 'UPLOAD_MISMATCH' } });
    const media = await h.owner.mediaObject.findUniqueOrThrow({ where: { id: ticket.id } });
    expect(media.status).toBe('rejected');
  });

  it('flags photos captured with a mock GPS location', async () => {
    const ticket = await register(photo('mock'), { isMockLocation: true });
    const items = await h.owner.reviewItem.findMany({ where: { subjectId: ticket.id } });
    expect(items.map((i) => i.kind)).toEqual(['mock_location']);
  });
});

describe('OCR reconciliation', () => {
  async function odometerPhotoWithReading(typedKm: number, metadata: Record<string, string>) {
    const orgId = owner.activeOrgId ?? '';
    const bytes = photo(`ocr-${typedKm}`);
    const ticket = await register(bytes);
    await putWithOcrMetadata(orgId, ticket.id, bytes, metadata);
    await request(h.http)
      .post(`/v1/media/${ticket.id}/complete`)
      .set(...bearer(owner))
      .expect(200);
    const vehicle = await h.owner.vehicle.create({
      data: {
        id: randomUUID(),
        orgId,
        registrationNo: `MH12OC${typedKm}`,
        make: 'Toyota',
        model: 'Innova',
        fuelType: 'diesel',
      },
    });
    const reading = await h.owner.odometerReading.create({
      data: {
        id: randomUUID(),
        orgId,
        vehicleId: vehicle.id,
        context: 'trip_start',
        typedKm,
        mediaId: ticket.id,
        capturedAt: new Date(),
        createdBy: owner.user.id,
      },
    });
    await runJobs(h);
    return { reading, mediaId: ticket.id };
  }

  it('stores the OCR value and raises a review item when it disagrees with the typed value', async () => {
    const { reading } = await odometerPhotoWithReading(48210, { 'ocr-km': '48270' });
    const updated = await h.owner.odometerReading.findUniqueOrThrow({ where: { id: reading.id } });
    expect(updated.ocrKm).toBe(48270);
    const items = await h.owner.reviewItem.findMany({ where: { subjectId: reading.id } });
    expect(items).toMatchObject([
      { kind: 'ocr_mismatch_odometer', typedValue: '48210', ocrValue: '48270', status: 'open' },
    ]);
  });

  it('raises nothing when OCR agrees within 1 km', async () => {
    const { reading } = await odometerPhotoWithReading(51000, { 'ocr-km': '51001' });
    expect(await h.owner.reviewItem.count({ where: { subjectId: reading.id } })).toBe(0);
  });

  it('asks for review when the photo is unreadable', async () => {
    const { reading } = await odometerPhotoWithReading(52000, { 'ocr-unreadable': 'true' });
    const items = await h.owner.reviewItem.findMany({ where: { subjectId: reading.id } });
    expect(items).toMatchObject([{ kind: 'ocr_mismatch_odometer', ocrValue: null }]);
  });
});
