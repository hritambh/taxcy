import { Injectable } from '@nestjs/common';
import type { GeoPoint, Trip } from '@taxcy/contracts';
import type { Prisma, TenantTx } from '@taxcy/db';
import { allowedCommands } from '@taxcy/domain';

const tripInclude = {
  vehicle: { select: { id: true, registrationNo: true, model: true } },
  driver: { select: { id: true, name: true, userId: true } },
  charges: { orderBy: { createdAt: 'asc' } },
  collections: { orderBy: { collectedAt: 'asc' } },
} as const satisfies Prisma.TripInclude;

export type TripRow = Prisma.TripGetPayload<{ include: typeof tripInclude }>;

type OdometerRow = Prisma.OdometerReadingGetPayload<object>;
type CancellationRow = Prisma.TripCancellationRequestGetPayload<object>;

const toNumber = (paise: bigint) => Number(paise);

function odometer(row: OdometerRow | undefined): Trip['startOdometer'] {
  return row
    ? {
        id: row.id,
        typedKm: row.typedKm,
        ocrKm: row.ocrKm,
        mediaId: row.mediaId,
        capturedAt: row.capturedAt,
      }
    : null;
}

@Injectable()
export class TripsRepository {
  /** Locks the trip row for the rest of the transaction (serialises concurrent commands). */
  async lock(tx: TenantTx, id: string): Promise<TripRow | null> {
    await tx.$queryRaw`SELECT id FROM trips WHERE id = ${id}::uuid AND org_id = ${tx.orgId}::uuid FOR UPDATE`;
    return this.findRow(tx, id);
  }

  async findRow(tx: TenantTx, id: string): Promise<TripRow | null> {
    return tx.trip.findFirst({ where: { id, orgId: tx.orgId }, include: tripInclude });
  }

  async findRows(tx: TenantTx, where: Prisma.TripWhereInput, take: number): Promise<TripRow[]> {
    return tx.trip.findMany({
      where: { ...where, orgId: tx.orgId },
      include: tripInclude,
      orderBy: { scheduledStartAt: 'desc' },
      take,
    });
  }

  async setPoints(
    tx: TenantTx,
    id: string,
    from: GeoPoint | null | undefined,
    to: GeoPoint | null | undefined,
  ): Promise<void> {
    const wkt = (p: GeoPoint | null | undefined) =>
      p ? `SRID=4326;POINT(${p.lng} ${p.lat})` : null;
    if (from !== undefined)
      await tx.$executeRaw`UPDATE trips SET from_point = ${wkt(from)}::geography WHERE id = ${id}::uuid`;
    if (to !== undefined)
      await tx.$executeRaw`UPDATE trips SET to_point = ${wkt(to)}::geography WHERE id = ${id}::uuid`;
  }

  async nextSeq(tx: TenantTx, tripId: string): Promise<number> {
    const max = await tx.tripEvent.aggregate({ where: { tripId }, _max: { seq: true } });
    return (max._max.seq ?? 0) + 1;
  }

  /** Full API views for rows, loading odometers, points and cancellation requests in bulk. */
  async views(tx: TenantTx, rows: readonly TripRow[]): Promise<Trip[]> {
    if (!rows.length) return [];
    const ids = rows.map((r) => r.id);
    const odometerIds = rows
      .flatMap((r) => [r.startOdometerId, r.endOdometerId])
      .filter((x): x is string => !!x);
    const customerIds = rows.map((r) => r.customerId).filter((x): x is string => !!x);
    const [points, requests, customers, fills] = await Promise.all([
      tx.$queryRaw<
        {
          id: string;
          from_lat: number | null;
          from_lng: number | null;
          to_lat: number | null;
          to_lng: number | null;
        }[]
      >`
        SELECT id,
          ST_Y(from_point::geometry) AS from_lat, ST_X(from_point::geometry) AS from_lng,
          ST_Y(to_point::geometry) AS to_lat, ST_X(to_point::geometry) AS to_lng
        FROM trips WHERE id = ANY(${ids}::uuid[])`,
      tx.tripCancellationRequest.findMany({
        where: { tripId: { in: ids } },
        orderBy: { createdAt: 'desc' },
      }),
      tx.customer.findMany({ where: { id: { in: customerIds } } }),
      tx.fuelFill.findMany({
        where: { tripId: { in: ids }, voidedAt: null },
        orderBy: { filledAt: 'asc' },
      }),
    ]);
    const customerById = new Map(customers.map((c) => [c.id, c]));
    const requestOdometerIds = requests.map((r) => r.endOdometerId).filter((x): x is string => !!x);
    const odometers = await tx.odometerReading.findMany({
      where: { id: { in: [...odometerIds, ...requestOdometerIds] } },
    });
    const odometerById = new Map(odometers.map((o) => [o.id, o]));
    const pointsById = new Map(points.map((p) => [p.id, p]));
    const requestByTrip = new Map<string, CancellationRow>();
    for (const request of requests) {
      const current = requestByTrip.get(request.tripId);
      // Prefer the pending request; otherwise the most recent one.
      if (!current || (request.status === 'pending' && current.status !== 'pending'))
        requestByTrip.set(request.tripId, request);
    }

    return rows.map((row) => {
      const p = pointsById.get(row.id);
      const point = (lat: number | null | undefined, lng: number | null | undefined) =>
        lat === null || lat === undefined || lng === null || lng === undefined
          ? null
          : { lat, lng };
      const request = requestByTrip.get(row.id);
      const pending = request?.status === 'pending';
      return {
        id: row.id,
        tripType: row.tripType,
        status: row.status,
        channel: row.channel,
        customer: (() => {
          const c = row.customerId ? customerById.get(row.customerId) : undefined;
          return c ? { name: c.name, phone: c.phoneE164 } : null;
        })(),
        from: { text: row.fromText, point: point(p?.from_lat, p?.from_lng) },
        to: row.toText ? { text: row.toText, point: point(p?.to_lat, p?.to_lng) } : null,
        scheduledStartAt: row.scheduledStartAt,
        scheduledEndAt: row.scheduledEndAt,
        vehicle: row.vehicle,
        driver: row.driver ? { id: row.driver.id, name: row.driver.name } : null,
        quotedFarePaise: toNumber(row.quotedFarePaise),
        cancellationFarePaise:
          row.cancellationFarePaise === null ? null : toNumber(row.cancellationFarePaise),
        startOdometer: odometer(
          row.startOdometerId ? odometerById.get(row.startOdometerId) : undefined,
        ),
        endOdometer: odometer(row.endOdometerId ? odometerById.get(row.endOdometerId) : undefined),
        startedAt: row.startedAt,
        endedAt: row.endedAt,
        cancelledAt: row.cancelledAt,
        cancelReason: row.cancelReason,
        cancellationRequest: request
          ? {
              id: request.id,
              status: request.status as 'pending' | 'approved' | 'rejected' | 'withdrawn',
              reason: request.reason,
              requestedBy: request.requestedBy,
              requestedRole: request.requestedRole,
              endOdometer: odometer(
                request.endOdometerId ? odometerById.get(request.endOdometerId) : undefined,
              ),
              decidedBy: request.decidedBy,
              decidedAt: request.decidedAt,
              decisionNote: request.decisionNote,
              createdAt: request.createdAt,
            }
          : null,
        charges: row.charges.map((c) => ({
          id: c.id,
          kind: c.kind as Trip['charges'][number]['kind'],
          amountPaise: toNumber(c.amountPaise),
          paidByDriver: c.paidByDriver,
          mediaId: c.mediaId,
          note: c.note,
          enteredBy: c.enteredBy,
          enteredRole: c.enteredRole,
          voidedAt: c.voidedAt,
          createdAt: c.createdAt,
        })),
        collections: row.collections.map((c) => ({
          id: c.id,
          method: c.method as Trip['collections'][number]['method'],
          amountPaise: toNumber(c.amountPaise),
          reference: c.reference,
          collectedAt: c.collectedAt,
        })),
        fuelFills: fills
          .filter((f) => f.tripId === row.id)
          .map((f) => ({
            id: f.id,
            fuel: f.fuel,
            quantityMilli: f.quantityMilli,
            costPaise: toNumber(f.costPaise),
            paidBy: f.paidBy as Trip['fuelFills'][number]['paidBy'],
            isFullTank: f.isFullTank,
            filledAt: f.filledAt,
          })),
        allowedCommands: allowedCommands({ status: row.status, cancellationPending: pending }),
        version: row.version,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      };
    });
  }
}
