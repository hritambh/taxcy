import { Injectable } from '@nestjs/common';
import type { GeoPoint, Trip, TripType } from '@taxcy/contracts';
import type { Prisma, TenantTx } from '@taxcy/db';
import { decideTransition, type TripActor, type TripCommand, type TripStatus } from '@taxcy/domain';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { AppError, notFound } from '../../platform/errors.js';
import { newId } from '../../platform/ids.js';
import { publish } from '../../platform/outbox.js';
import type { Patch } from '../../platform/patch.js';
import { Db } from '../../platform/prisma.service.js';
import { AlertsRepository } from '../alerts/alerts.repository.js';
import { ReviewItemsRepository } from '../alerts/review-items.repository.js';
import { EvidenceReconciler } from '../media/evidence.reconciler.js';
import { TripsRepository, type TripRow } from './trips.repository.js';

export interface OdometerInput {
  id: string;
  typedKm: number;
  mediaId: string;
  capturedAt: Date;
}

export interface ChargeInput {
  id: string;
  kind: string;
  amountPaise: number;
  paidByDriver: boolean;
  mediaId?: string | undefined;
  note?: string | undefined;
}

export interface CollectionInput {
  id: string;
  method: 'cash' | 'upi' | 'card';
  amountPaise: number;
  reference?: string | undefined;
  collectedAt?: Date | undefined;
}

interface TripDetailsInput {
  tripType: TripType;
  customer?: { name: string; phone?: string | undefined } | undefined;
  from: { text: string; point?: GeoPoint | null | undefined };
  to?: { text: string; point?: GeoPoint | null | undefined } | undefined;
  scheduledStartAt: Date;
  scheduledEndAt: Date;
  quotedFarePaise: number;
}

const EVENT_TYPES: Record<TripCommand, string> = {
  assign: 'trip.assigned',
  reassign: 'trip.reassigned',
  unassign: 'trip.unassigned',
  start: 'trip.started',
  end: 'trip.ended',
  requestCancel: 'trip.cancellation_requested',
  approveCancel: 'trip.cancellation_approved',
  rejectCancel: 'trip.cancellation_rejected',
  withdrawCancel: 'trip.cancellation_withdrawn',
  cancel: 'trip.cancelled',
  settle: 'trip.settled',
};

@Injectable()
export class TripsService {
  constructor(
    private readonly db: Db,
    private readonly trips: TripsRepository,
    private readonly reviews: ReviewItemsRepository,
    private readonly alerts: AlertsRepository,
    private readonly evidence: EvidenceReconciler,
  ) {}

  // ───────── queries ─────────

  async get(auth: TenantAuth, id: string): Promise<Trip> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const row = await this.trips.findRow(tx, id);
      if (!row || !(await this.canSee(tx, auth, row))) throw notFound('Trip');
      return this.view(tx, row);
    });
  }

  async list(
    auth: TenantAuth,
    q: {
      status?: TripStatus | undefined;
      driverId?: string | undefined;
      vehicleId?: string | undefined;
      from?: Date | undefined;
      to?: Date | undefined;
      limit: number;
    },
  ): Promise<Trip[]> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const rows = await this.trips.findRows(
        tx,
        {
          ...(q.status ? { status: q.status } : {}),
          ...(q.driverId ? { driverId: q.driverId } : {}),
          ...(q.vehicleId ? { vehicleId: q.vehicleId } : {}),
          ...(q.from || q.to
            ? {
                scheduledStartAt: {
                  ...(q.from ? { gte: q.from } : {}),
                  ...(q.to ? { lt: q.to } : {}),
                },
              }
            : {}),
        },
        q.limit,
      );
      return this.trips.views(tx, rows);
    });
  }

  /** The driver's active trips plus anything recent or changed since the app last synced. */
  async myTrips(auth: TenantAuth, since: Date | undefined): Promise<Trip[]> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const driver = await tx.driver.findFirst({
        where: { orgId: tx.orgId, userId: auth.userId },
        select: { id: true },
      });
      if (!driver) return [];
      const recent = new Date(Date.now() - 2 * 86_400_000);
      const rows = await this.trips.findRows(
        tx,
        {
          driverId: driver.id,
          OR: [
            { status: { in: ['assigned', 'started'] } },
            { scheduledStartAt: { gte: recent } },
            ...(since ? [{ updatedAt: { gte: since } }] : []),
          ],
        },
        200,
      );
      return this.trips.views(tx, rows);
    });
  }

  async events(auth: TenantAuth, id: string) {
    return this.db.tenant(auth.orgId, async (tx) => {
      const row = await this.trips.findRow(tx, id);
      if (!row || !(await this.canSee(tx, auth, row))) throw notFound('Trip');
      const events = await tx.tripEvent.findMany({
        where: { tripId: id, orgId: tx.orgId },
        orderBy: { seq: 'asc' },
      });
      return events.map((e) => ({ ...e, payload: (e.payload ?? {}) as Record<string, unknown> }));
    });
  }

  // ───────── create / edit ─────────

  async create(
    auth: TenantAuth,
    input: TripDetailsInput & { vehicleId?: string | undefined; driverId?: string | undefined },
  ): Promise<Trip> {
    this.assertSchedule(input.scheduledStartAt, input.scheduledEndAt);
    if (input.tripType !== 'local_rental' && !input.to) {
      throw new AppError('VALIDATION_FAILED', 'One-way and round trips need a drop location');
    }
    if (Boolean(input.vehicleId) !== Boolean(input.driverId)) {
      throw new AppError('VALIDATION_FAILED', 'Assign a vehicle and a driver together');
    }
    return this.db.tenant(auth.orgId, async (tx) => {
      const id = newId();
      await tx.trip.create({
        data: {
          id,
          orgId: tx.orgId,
          tripType: input.tripType,
          customerId: await this.customerId(tx, input.customer),
          fromText: input.from.text,
          toText: input.to?.text ?? null,
          scheduledStartAt: input.scheduledStartAt,
          scheduledEndAt: input.scheduledEndAt,
          quotedFarePaise: BigInt(input.quotedFarePaise),
          createdBy: auth.userId,
        },
      });
      await this.trips.setPoints(tx, id, input.from.point ?? null, input.to?.point ?? null);
      await this.appendEvent(tx, id, auth, {
        id: newId(),
        eventType: 'trip.created',
        from: null,
        to: 'created',
        occurredAt: new Date(),
        payload: { quotedFarePaise: input.quotedFarePaise },
      });
      if (input.vehicleId && input.driverId) {
        await this.applyInTx(tx, auth, id, 'assign', newId(), new Date(), async (trip) => {
          await this.assignVehicleAndDriver(tx, trip, input.vehicleId ?? '', input.driverId ?? '');
          return { vehicleId: input.vehicleId, driverId: input.driverId };
        });
      }
      return this.requireView(tx, id);
    });
  }

  async update(auth: TenantAuth, id: string, patch: Patch<TripDetailsInput>): Promise<Trip> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const row = await this.trips.lock(tx, id);
      if (!row) throw notFound('Trip');
      if (row.status !== 'created' && row.status !== 'assigned') {
        throw new AppError('ILLEGAL_TRANSITION', 'Only trips that have not started can be edited');
      }
      const start = patch.scheduledStartAt ?? row.scheduledStartAt;
      const end = patch.scheduledEndAt ?? row.scheduledEndAt;
      this.assertSchedule(start, end);
      await tx.trip.update({
        where: { id },
        data: {
          ...(patch.tripType ? { tripType: patch.tripType } : {}),
          ...(patch.customer ? { customerId: await this.customerId(tx, patch.customer) } : {}),
          ...(patch.from ? { fromText: patch.from.text } : {}),
          ...(patch.to ? { toText: patch.to.text } : {}),
          ...(patch.quotedFarePaise === undefined
            ? {}
            : { quotedFarePaise: BigInt(patch.quotedFarePaise) }),
          scheduledStartAt: start,
          scheduledEndAt: end,
          version: { increment: 1 },
        },
      });
      await this.trips.setPoints(
        tx,
        id,
        patch.from ? (patch.from.point ?? null) : undefined,
        patch.to ? (patch.to.point ?? null) : undefined,
      );
      await this.appendEvent(tx, id, auth, {
        id: newId(),
        eventType: 'trip.updated',
        from: row.status,
        to: row.status,
        occurredAt: new Date(),
        payload: { fields: Object.keys(patch) },
      });
      return this.requireView(tx, id);
    });
  }

  // ───────── commands ─────────

  async assign(
    auth: TenantAuth,
    id: string,
    key: string,
    input: { vehicleId: string; driverId: string },
  ): Promise<Trip> {
    return this.command(
      auth,
      id,
      key,
      new Date(),
      (trip) => (trip.status === 'created' ? 'assign' : 'reassign'),
      async (tx, trip) => {
        await this.assignVehicleAndDriver(tx, trip, input.vehicleId, input.driverId);
        return {
          vehicleId: input.vehicleId,
          driverId: input.driverId,
          previousDriverId: trip.driverId,
        };
      },
    );
  }

  async unassign(auth: TenantAuth, id: string, key: string): Promise<Trip> {
    return this.command(
      auth,
      id,
      key,
      new Date(),
      () => 'unassign',
      async (tx, trip) => {
        await tx.trip.update({ where: { id: trip.id }, data: { vehicleId: null, driverId: null } });
        return { previousDriverId: trip.driverId, previousVehicleId: trip.vehicleId };
      },
    );
  }

  async start(
    auth: TenantAuth,
    id: string,
    key: string,
    input: { odometer: OdometerInput; occurredAt: Date },
  ): Promise<Trip> {
    try {
      return await this.command(
        auth,
        id,
        key,
        input.occurredAt,
        () => 'start',
        async (tx, trip) => {
          const reading = await this.recordOdometer(tx, auth, trip, input.odometer, 'trip_start');
          await tx.trip.update({
            where: { id: trip.id },
            data: { startOdometerId: reading.id, startedAt: input.occurredAt },
          });
          return { odometerReadingId: reading.id, typedKm: reading.typedKm };
        },
      );
    } catch (error) {
      throw await this.keepOrphanEvidence(auth, id, error, input.odometer, 'trip_start');
    }
  }

  async end(
    auth: TenantAuth,
    id: string,
    key: string,
    input: {
      odometer: OdometerInput;
      occurredAt: Date;
      collections: CollectionInput[];
      charges: ChargeInput[];
    },
  ): Promise<Trip> {
    try {
      return await this.command(
        auth,
        id,
        key,
        input.occurredAt,
        () => 'end',
        async (tx, trip) => {
          const start = trip.startOdometerId
            ? await tx.odometerReading.findUnique({
                where: { id: trip.startOdometerId },
                select: { typedKm: true },
              })
            : null;
          if (start && input.odometer.typedKm < start.typedKm) {
            throw new AppError(
              'ODOMETER_BEFORE_START',
              `End reading ${input.odometer.typedKm} km is below the start reading ${start.typedKm} km`,
            );
          }
          const reading = await this.recordOdometer(tx, auth, trip, input.odometer, 'trip_end');
          await tx.trip.update({
            where: { id: trip.id },
            data: { endOdometerId: reading.id, endedAt: input.occurredAt },
          });
          await this.insertCharges(tx, auth, trip, input.charges);
          await this.insertCollections(tx, trip, input.collections, input.occurredAt);
          // Ending supersedes a pending cancellation request.
          await this.closePendingRequest(tx, trip.id, 'withdrawn', auth.userId, 'Trip was ended');
          await publish(tx, 'trip.closed', { tripId: trip.id });
          return {
            odometerReadingId: reading.id,
            typedKm: reading.typedKm,
            distanceKm: start ? reading.typedKm - start.typedKm : null,
            collections: input.collections.length,
            charges: input.charges.length,
          };
        },
      );
    } catch (error) {
      throw await this.keepOrphanEvidence(auth, id, error, input.odometer, 'trip_end');
    }
  }

  async cancel(auth: TenantAuth, id: string, key: string, reason: string): Promise<Trip> {
    return this.command(
      auth,
      id,
      key,
      new Date(),
      () => 'cancel',
      async (tx, trip) => {
        await tx.trip.update({
          where: { id: trip.id },
          data: { cancelledAt: new Date(), cancelReason: reason },
        });
        return { reason };
      },
    );
  }

  async requestCancellation(
    auth: TenantAuth,
    tripId: string,
    key: string,
    input: { id: string; reason: string; endOdometer: OdometerInput; occurredAt: Date },
  ): Promise<Trip> {
    return this.command(
      auth,
      tripId,
      key,
      input.occurredAt,
      () => 'requestCancel',
      async (tx, trip, actors) => {
        const reading = await this.recordOdometer(tx, auth, trip, input.endOdometer, 'trip_end');
        await tx.tripCancellationRequest.create({
          data: {
            id: input.id,
            orgId: tx.orgId,
            tripId: trip.id,
            requestedBy: auth.userId,
            requestedRole: actors.includes('staff')
              ? auth.roles.includes('owner')
                ? 'owner'
                : 'manager'
              : 'driver',
            reason: input.reason,
            endOdometerId: reading.id,
          },
        });
        await this.alerts.raise(tx, {
          kind: 'cancellation_requested',
          severity: 'warning',
          title: `Cancellation requested for the trip from ${trip.fromText}`,
          explanation: `${trip.driver?.name ?? 'The driver'} asked to cancel this running trip: "${input.reason}". The odometer read ${input.endOdometer.typedKm} km. Approve (optionally with a cancellation fare) or reject it on the trip page.`,
          subjectType: 'trip',
          subjectId: trip.id,
          tripId: trip.id,
          vehicleId: trip.vehicleId,
          driverId: trip.driverId,
          dedupeKey: `cancel:${input.id}`,
        });
        return { requestId: input.id, reason: input.reason, typedKm: input.endOdometer.typedKm };
      },
    );
  }

  async approveCancellation(
    auth: TenantAuth,
    requestId: string,
    key: string,
    input: { cancellationFarePaise: number; note?: string | undefined },
  ): Promise<Trip> {
    const tripId = await this.tripIdForRequest(auth, requestId);
    return this.command(
      auth,
      tripId,
      key,
      new Date(),
      () => 'approveCancel',
      async (tx, trip) => {
        const request = await this.pendingRequest(tx, trip.id, requestId);
        await tx.tripCancellationRequest.update({
          where: { id: request.id },
          data: {
            status: 'approved',
            decidedBy: auth.userId,
            decidedAt: new Date(),
            decisionNote: input.note ?? null,
          },
        });
        await tx.trip.update({
          where: { id: trip.id },
          data: {
            cancelledAt: new Date(),
            cancelReason: request.reason,
            cancellationFarePaise: BigInt(input.cancellationFarePaise),
            endOdometerId: request.endOdometerId,
          },
        });
        await this.alerts.autoResolve(tx, `cancel:${request.id}`);
        await publish(tx, 'trip.closed', { tripId: trip.id });
        return { requestId, cancellationFarePaise: input.cancellationFarePaise };
      },
    );
  }

  async rejectCancellation(
    auth: TenantAuth,
    requestId: string,
    key: string,
    note: string,
  ): Promise<Trip> {
    const tripId = await this.tripIdForRequest(auth, requestId);
    return this.command(
      auth,
      tripId,
      key,
      new Date(),
      () => 'rejectCancel',
      async (tx, trip) => {
        await this.pendingRequest(tx, trip.id, requestId);
        await this.closePendingRequest(tx, trip.id, 'rejected', auth.userId, note);
        return { requestId, note };
      },
    );
  }

  async withdrawCancellation(auth: TenantAuth, requestId: string, key: string): Promise<Trip> {
    const tripId = await this.tripIdForRequest(auth, requestId);
    return this.command(
      auth,
      tripId,
      key,
      new Date(),
      () => 'withdrawCancel',
      async (tx, trip) => {
        await this.pendingRequest(tx, trip.id, requestId);
        await this.closePendingRequest(tx, trip.id, 'withdrawn', auth.userId, null);
        return { requestId };
      },
    );
  }

  /** Charges can be added by the assigned driver or staff until the trip is settled. Idempotent on charge id. */
  async addCharge(auth: TenantAuth, tripId: string, charge: ChargeInput): Promise<Trip> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const trip = await this.trips.lock(tx, tripId);
      if (!trip || !(await this.canSee(tx, auth, trip))) throw notFound('Trip');
      if (trip.status === 'settled')
        throw new AppError('ALREADY_SETTLED', 'This trip has been settled');
      if (trip.status === 'cancelled' && trip.cancelledAt && !trip.startedAt) {
        throw new AppError('TRIP_CANCELLED', 'This trip was cancelled before it started');
      }
      const existing = await tx.tripCharge.findUnique({
        where: { id: charge.id },
        select: { tripId: true },
      });
      if (existing && existing.tripId !== tripId)
        throw new AppError('IDEMPOTENCY_CONFLICT', 'Charge id already used on another trip');
      if (!existing) {
        await this.insertCharges(tx, auth, trip, [charge]);
        await this.appendEvent(tx, trip.id, auth, {
          id: newId(),
          eventType: 'trip.charge_added',
          from: trip.status,
          to: trip.status,
          occurredAt: new Date(),
          payload: { chargeId: charge.id, kind: charge.kind, amountPaise: charge.amountPaise },
        });
      }
      return this.requireView(tx, tripId);
    });
  }

  async voidCharge(auth: TenantAuth, tripId: string, chargeId: string): Promise<Trip> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const trip = await this.trips.lock(tx, tripId);
      if (!trip) throw notFound('Trip');
      if (trip.status === 'settled')
        throw new AppError('ALREADY_SETTLED', 'This trip has been settled');
      const updated = await tx.tripCharge.updateMany({
        where: { id: chargeId, tripId, orgId: tx.orgId, voidedAt: null },
        data: { voidedAt: new Date() },
      });
      if (updated.count) {
        await this.appendEvent(tx, trip.id, auth, {
          id: newId(),
          eventType: 'trip.charge_voided',
          from: trip.status,
          to: trip.status,
          occurredAt: new Date(),
          payload: { chargeId },
        });
      }
      return this.requireView(tx, tripId);
    });
  }

  /** Marks ended trips settled (called by settlements, inside their transaction). */
  async settleInTx(tx: TenantTx, auth: TenantAuth, tripIds: readonly string[]): Promise<void> {
    for (const id of tripIds) {
      await this.applyInTx(tx, auth, id, 'settle', newId(), new Date(), () => Promise.resolve({}), [
        'system',
      ]);
    }
  }

  // ───────── internals ─────────

  /**
   * Runs one state-machine command in a transaction: lock, replay check (the
   * Idempotency-Key is the event id), authorise via the domain transition table,
   * apply, bump the version, append the event.
   */
  private async command(
    auth: TenantAuth,
    id: string,
    key: string,
    occurredAt: Date,
    pick: (trip: TripRow) => TripCommand,
    apply: (tx: TenantTx, trip: TripRow, actors: TripActor[]) => Promise<Prisma.InputJsonObject>,
  ): Promise<Trip> {
    return this.db.tenant(auth.orgId, async (tx) => {
      const trip = await this.trips.lock(tx, id);
      if (!trip) throw notFound('Trip');
      if (await tx.tripEvent.findUnique({ where: { id: key }, select: { id: true } })) {
        return this.requireView(tx, id); // replay of a command that already applied
      }
      await this.applyInTx(tx, auth, id, pick(trip), key, occurredAt, (row, actors) =>
        apply(tx, row, actors),
      );
      return this.requireView(tx, id);
    });
  }

  private async applyInTx(
    tx: TenantTx,
    auth: TenantAuth,
    id: string,
    command: TripCommand,
    eventId: string,
    occurredAt: Date,
    apply: (trip: TripRow, actors: TripActor[]) => Promise<Prisma.InputJsonObject>,
    forcedActors?: TripActor[],
  ): Promise<void> {
    const trip = await this.trips.lock(tx, id);
    if (!trip) throw notFound('Trip');
    const pending = await tx.tripCancellationRequest.findFirst({
      where: { tripId: id, status: 'pending' },
    });
    const actors = forcedActors ?? this.actorsFor(auth, trip, pending?.requestedBy ?? null);
    const decision = decideTransition(
      { status: trip.status, cancellationPending: Boolean(pending) },
      command,
      actors,
    );
    if (!decision.ok)
      throw await this.rejection(
        tx,
        auth,
        trip,
        decision.error,
        decision.message,
        decision.allowed,
      );

    const payload = await apply(trip, actors);
    const updated = await tx.trip.updateMany({
      where: { id, version: trip.version },
      data: { status: decision.to, version: { increment: 1 } },
    });
    if (!updated.count)
      throw new AppError(
        'VERSION_CONFLICT',
        'The trip changed while this request was being processed; retry',
      );
    await this.appendEvent(tx, id, auth, {
      id: eventId,
      eventType: EVENT_TYPES[command],
      from: trip.status,
      to: decision.to,
      occurredAt,
      payload,
      actorRole: forcedActors?.includes('system') ? null : undefined,
    });
  }

  private async rejection(
    tx: TenantTx,
    auth: TenantAuth,
    trip: TripRow,
    code: 'ILLEGAL_TRANSITION' | 'TRIP_CANCELLED' | 'CANCELLATION_PENDING' | 'FORBIDDEN_ROLE',
    message: string,
    allowed: TripCommand[],
  ): Promise<AppError> {
    if (code === 'FORBIDDEN_ROLE' && !this.isStaff(auth)) {
      // A driver acting on a trip that was reassigned while their phone was offline.
      const wasAssigned = await tx.tripEvent.count({
        where: {
          tripId: trip.id,
          eventType: { in: ['trip.assigned', 'trip.reassigned'] },
          payload: { path: ['driverId'], equals: (await this.myDriverId(tx, auth)) ?? '' },
        },
      });
      if (wasAssigned)
        return new AppError('TRIP_REASSIGNED', 'This trip has been reassigned to another driver');
      return notFound('Trip');
    }
    const details =
      code === 'TRIP_CANCELLED'
        ? { allowed, cancelledAt: trip.cancelledAt, reason: trip.cancelReason }
        : { allowed, status: trip.status };
    return new AppError(code, message, details);
  }

  /**
   * A start/end rejected because the trip was cancelled while the phone was offline:
   * the odometer photo is still evidence, so it's recorded against the trip and
   * queued for review. This runs in its own transaction, since the command's rolled back.
   */
  private async keepOrphanEvidence(
    auth: TenantAuth,
    tripId: string,
    error: unknown,
    odometer: OdometerInput,
    context: 'trip_start' | 'trip_end',
  ): Promise<unknown> {
    if (!(error instanceof AppError) || error.code !== 'TRIP_CANCELLED') return error;
    await this.db.tenant(auth.orgId, async (tx) => {
      const trip = await this.trips.findRow(tx, tripId);
      if (!trip?.vehicleId) return;
      const exists = await tx.odometerReading.findUnique({
        where: { id: odometer.id },
        select: { id: true },
      });
      if (!exists) await this.recordOdometer(tx, auth, trip, odometer, context);
      await this.reviews.raise(tx, {
        kind: 'orphan_evidence',
        subjectType: 'odometer_reading',
        subjectId: odometer.id,
        mediaId: odometer.mediaId,
        typedValue: String(odometer.typedKm),
        context: {
          tripId,
          reason: `Driver tried to ${context === 'trip_start' ? 'start' : 'end'} the trip after it was cancelled`,
        },
      });
    });
    return error;
  }

  private actorsFor(auth: TenantAuth, trip: TripRow, requesterId: string | null): TripActor[] {
    const actors: TripActor[] = [];
    if (this.isStaff(auth)) actors.push('staff');
    if (trip.driver?.userId === auth.userId && auth.roles.includes('driver'))
      actors.push('assigned_driver');
    if (requesterId === auth.userId) actors.push('requester');
    return actors;
  }

  private isStaff(auth: TenantAuth): boolean {
    return auth.roles.includes('owner') || auth.roles.includes('manager');
  }

  private async myDriverId(tx: TenantTx, auth: TenantAuth): Promise<string | null> {
    const driver = await tx.driver.findFirst({
      where: { orgId: tx.orgId, userId: auth.userId },
      select: { id: true },
    });
    return driver?.id ?? null;
  }

  private async canSee(tx: TenantTx, auth: TenantAuth, trip: TripRow): Promise<boolean> {
    if (this.isStaff(auth)) return true;
    return trip.driver?.userId === auth.userId || (await this.wasMine(tx, auth, trip.id));
  }

  private async wasMine(tx: TenantTx, auth: TenantAuth, tripId: string): Promise<boolean> {
    const driverId = await this.myDriverId(tx, auth);
    if (!driverId) return false;
    return (
      (await tx.tripEvent.count({
        where: { tripId, payload: { path: ['driverId'], equals: driverId } },
      })) > 0
    );
  }

  private async assignVehicleAndDriver(
    tx: TenantTx,
    trip: TripRow,
    vehicleId: string,
    driverId: string,
  ): Promise<void> {
    const [vehicle, driver] = await Promise.all([
      tx.vehicle.findFirst({ where: { id: vehicleId, orgId: tx.orgId }, select: { status: true } }),
      tx.driver.findFirst({ where: { id: driverId, orgId: tx.orgId }, select: { status: true } }),
    ]);
    if (!vehicle) throw notFound('Vehicle');
    if (!driver) throw notFound('Driver');
    if (vehicle.status !== 'active' || driver.status !== 'active') {
      throw new AppError('CONFLICT', 'Inactive vehicles and drivers cannot be assigned');
    }
    // The busy_window exclusion constraints reject overlapping bookings (→ VEHICLE_BUSY / DRIVER_BUSY).
    // The status changes to 'assigned' in the same statement so the constraint sees it.
    await tx.trip.update({
      where: { id: trip.id },
      data: { vehicleId, driverId, ...(trip.status === 'created' ? { status: 'assigned' } : {}) },
    });
  }

  private async recordOdometer(
    tx: TenantTx,
    auth: TenantAuth,
    trip: TripRow,
    input: OdometerInput,
    context: 'trip_start' | 'trip_end',
  ): Promise<{ id: string; typedKm: number }> {
    if (!trip.vehicleId)
      throw new AppError('ILLEGAL_TRANSITION', 'The trip has no vehicle assigned');
    const media = await tx.mediaObject.findFirst({
      where: { id: input.mediaId, orgId: tx.orgId },
      select: { kind: true },
    });
    if (!media)
      throw new AppError(
        'VALIDATION_FAILED',
        'Register the odometer photo (POST /media) before using it',
      );
    const existing = await tx.odometerReading.findUnique({ where: { id: input.id } });
    if (existing) return existing;
    const reading = await tx.odometerReading.create({
      data: {
        id: input.id,
        orgId: tx.orgId,
        vehicleId: trip.vehicleId,
        context,
        typedKm: input.typedKm,
        mediaId: input.mediaId,
        capturedAt: input.capturedAt,
        createdBy: auth.userId,
      },
    });
    const vehicle = await tx.vehicle.findUniqueOrThrow({
      where: { id: trip.vehicleId },
      select: { lastOdometerKm: true, registrationNo: true },
    });
    if (
      context === 'trip_start' &&
      vehicle.lastOdometerKm !== null &&
      input.typedKm < vehicle.lastOdometerKm
    ) {
      await this.reviews.raise(tx, {
        kind: 'odometer_regression',
        subjectType: 'odometer_reading',
        subjectId: reading.id,
        mediaId: input.mediaId,
        typedValue: String(input.typedKm),
        context: {
          previousKm: vehicle.lastOdometerKm,
          reason: `${vehicle.registrationNo} was last recorded at ${vehicle.lastOdometerKm} km, higher than this start reading`,
        },
      });
    }
    if (vehicle.lastOdometerKm === null || input.typedKm > vehicle.lastOdometerKm) {
      await tx.vehicle.update({
        where: { id: trip.vehicleId },
        data: { lastOdometerKm: input.typedKm },
      });
    }
    await this.evidence.reconcileOdometerMedia(tx, input.mediaId);
    return reading;
  }

  private async insertCharges(
    tx: TenantTx,
    auth: TenantAuth,
    trip: TripRow,
    charges: readonly ChargeInput[],
  ): Promise<void> {
    if (!charges.length) return;
    await tx.tripCharge.createMany({
      data: charges.map((c) => ({
        id: c.id,
        orgId: tx.orgId,
        tripId: trip.id,
        kind: c.kind,
        amountPaise: BigInt(c.amountPaise),
        paidByDriver: c.paidByDriver,
        mediaId: c.mediaId ?? null,
        note: c.note ?? null,
        enteredBy: auth.userId,
        enteredRole: this.isStaff(auth)
          ? auth.roles.includes('owner')
            ? 'owner'
            : 'manager'
          : 'driver',
      })),
      skipDuplicates: true,
    });
  }

  private async insertCollections(
    tx: TenantTx,
    trip: TripRow,
    collections: readonly CollectionInput[],
    at: Date,
  ): Promise<void> {
    if (!collections.length || !trip.driverId) return;
    const driverId = trip.driverId;
    await tx.tripCollection.createMany({
      data: collections.map((c) => ({
        id: c.id,
        orgId: tx.orgId,
        tripId: trip.id,
        driverId,
        method: c.method,
        amountPaise: BigInt(c.amountPaise),
        reference: c.reference ?? null,
        collectedAt: c.collectedAt ?? at,
      })),
      skipDuplicates: true,
    });
  }

  private async tripIdForRequest(auth: TenantAuth, requestId: string): Promise<string> {
    const request = await this.db.tenant(auth.orgId, (tx) =>
      tx.tripCancellationRequest.findFirst({
        where: { id: requestId, orgId: tx.orgId },
        select: { tripId: true },
      }),
    );
    if (!request) throw notFound('Cancellation request');
    return request.tripId;
  }

  private async pendingRequest(tx: TenantTx, tripId: string, requestId: string) {
    const request = await tx.tripCancellationRequest.findFirst({
      where: { id: requestId, tripId, status: 'pending' },
    });
    if (!request)
      throw new AppError('ILLEGAL_TRANSITION', 'This cancellation request is no longer pending');
    return request;
  }

  private async closePendingRequest(
    tx: TenantTx,
    tripId: string,
    status: 'rejected' | 'withdrawn',
    userId: string,
    note: string | null,
  ): Promise<void> {
    const pending = await tx.tripCancellationRequest.findFirst({
      where: { tripId, status: 'pending' },
      select: { id: true },
    });
    if (!pending) return;
    await tx.tripCancellationRequest.update({
      where: { id: pending.id },
      data: { status, decidedBy: userId, decidedAt: new Date(), decisionNote: note },
    });
    await this.alerts.autoResolve(tx, `cancel:${pending.id}`);
  }

  private async appendEvent(
    tx: TenantTx,
    tripId: string,
    auth: TenantAuth,
    event: {
      id: string;
      eventType: string;
      from: TripStatus | null;
      to: TripStatus | null;
      occurredAt: Date;
      payload: Prisma.InputJsonObject;
      actorRole?: null | undefined;
    },
  ): Promise<void> {
    const role =
      event.actorRole === null
        ? null
        : this.isStaff(auth)
          ? auth.roles.includes('owner')
            ? 'owner'
            : 'manager'
          : 'driver';
    await tx.tripEvent.create({
      data: {
        id: event.id,
        orgId: tx.orgId,
        tripId,
        seq: await this.trips.nextSeq(tx, tripId),
        eventType: event.eventType,
        fromStatus: event.from,
        toStatus: event.to,
        actorUserId: event.actorRole === null ? null : auth.userId,
        actorRole: role,
        occurredAt: event.occurredAt,
        payload: event.payload,
      },
    });
  }

  private async customerId(
    tx: TenantTx,
    customer: { name: string; phone?: string | undefined } | undefined,
  ): Promise<string | null> {
    if (!customer) return null;
    if (customer.phone) {
      const existing = await tx.customer.findFirst({
        where: { orgId: tx.orgId, phoneE164: customer.phone },
        select: { id: true },
      });
      if (existing) return existing.id;
    }
    const id = newId();
    await tx.customer.create({
      data: { id, orgId: tx.orgId, name: customer.name, phoneE164: customer.phone ?? null },
    });
    return id;
  }

  private assertSchedule(start: Date, end: Date): void {
    if (end <= start)
      throw new AppError('VALIDATION_FAILED', 'The scheduled end must be after the start');
  }

  private async view(tx: TenantTx, row: TripRow): Promise<Trip> {
    const [trip] = await this.trips.views(tx, [row]);
    if (!trip) throw notFound('Trip');
    return trip;
  }

  private async requireView(tx: TenantTx, id: string): Promise<Trip> {
    const row = await this.trips.findRow(tx, id);
    if (!row) throw notFound('Trip');
    return this.view(tx, row);
  }
}
