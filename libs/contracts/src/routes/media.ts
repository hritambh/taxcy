import { z } from 'zod';
import { DateTime, Id } from '../common.js';
import { access, defineRoute } from '../http.js';

export const MediaKind = z.enum(['odometer', 'fuel_receipt', 'document', 'other']);
export type MediaKind = z.infer<typeof MediaKind>;

export const GeoPoint = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});
export type GeoPoint = z.infer<typeof GeoPoint>;

export const MediaStatus = z.enum(['pending', 'uploaded', 'rejected']);
export type MediaStatus = z.infer<typeof MediaStatus>;

export const MediaObject = z.object({
  id: Id,
  kind: MediaKind,
  status: MediaStatus,
  contentType: z.string(),
  capturedAt: DateTime,
  uploadedAt: DateTime.nullable(),
});

export const UploadTicket = MediaObject.extend({
  /** Signed PUT URL; null once the object is uploaded. */
  uploadUrl: z.url().nullable(),
  /** Headers the client must send with the PUT. */
  uploadHeaders: z.record(z.string(), z.string()),
  uploadUrlExpiresAt: DateTime.nullable(),
});

export const mediaRoutes = {
  create: defineRoute({
    method: 'POST',
    path: '/media',
    summary: 'Register a captured photo and get a signed upload URL (idempotent on id)',
    tag: 'media',
    access: access.anyMember,
    status: 201,
    body: z.object({
      id: Id,
      kind: MediaKind,
      contentType: z.enum(['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
      sha256: z.string().regex(/^[0-9a-f]{64}$/, 'Expected a lowercase hex SHA-256'),
      byteSize: z
        .number()
        .int()
        .positive()
        .max(15 * 1024 * 1024),
      capturedAt: DateTime,
      location: GeoPoint.extend({ accuracyM: z.number().nonnegative().optional() }).optional(),
      isMockLocation: z.boolean().optional(),
      deviceId: Id.optional(),
    }),
    response: UploadTicket,
  }),
  complete: defineRoute({
    method: 'POST',
    path: '/media/{id}/complete',
    summary: 'Confirm the upload; the server verifies size and checksum',
    tag: 'media',
    access: access.anyMember,
    params: z.object({ id: Id }),
    response: MediaObject,
  }),
  url: defineRoute({
    method: 'GET',
    path: '/media/{id}/url',
    summary: 'Short-lived signed URL to view an uploaded object',
    tag: 'media',
    access: access.anyMember,
    params: z.object({ id: Id }),
    response: z.object({ url: z.url(), expiresAt: DateTime }),
  }),
};
