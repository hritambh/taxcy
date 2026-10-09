import { Injectable } from '@nestjs/common';
import type { Trip } from '@taxcy/contracts';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { AppError, notFound } from '../../platform/errors.js';
import { Db } from '../../platform/prisma.service.js';
import { TripsService, type CollectionInput } from '../trips/trips.service.js';

@Injectable()
export class CollectionsService {
  constructor(
    private readonly db: Db,
    private readonly trips: TripsService,
  ) {}

  /**
   * Records a payment on a trip. Allowed once the trip has started, including after
   * it's settled: a late collection is carried into the driver's next settlement.
   */
  async add(auth: TenantAuth, tripId: string, input: CollectionInput): Promise<Trip> {
    await this.db.tenant(auth.orgId, async (tx) => {
      const trip = await tx.trip.findFirst({
        where: { id: tripId, orgId: tx.orgId },
        include: { driver: { select: { id: true, userId: true } } },
      });
      const isStaff = auth.roles.includes('owner') || auth.roles.includes('manager');
      if (!trip?.driver || (!isStaff && trip.driver.userId !== auth.userId)) throw notFound('Trip');
      if (!trip.startedAt)
        throw new AppError(
          'ILLEGAL_TRANSITION',
          'Payments can be recorded once the trip has started',
        );
      const existing = await tx.tripCollection.findUnique({
        where: { id: input.id },
        select: { tripId: true, amountPaise: true },
      });
      if (existing) {
        if (existing.tripId !== tripId || Number(existing.amountPaise) !== input.amountPaise) {
          throw new AppError(
            'IDEMPOTENCY_CONFLICT',
            'This collection id was already used with different values',
          );
        }
        return;
      }
      await tx.tripCollection.create({
        data: {
          id: input.id,
          orgId: tx.orgId,
          tripId,
          driverId: trip.driver.id,
          method: input.method,
          amountPaise: BigInt(input.amountPaise),
          reference: input.reference ?? null,
          collectedAt: input.collectedAt ?? new Date(),
        },
      });
    });
    return this.trips.get(auth, tripId);
  }
}
