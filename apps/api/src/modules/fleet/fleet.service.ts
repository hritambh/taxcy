import { Injectable } from '@nestjs/common';
import type { Driver, FuelType, PayRule, Vehicle } from '@taxcy/contracts';
import { Prisma, type TenantTx } from '@taxcy/db';
import { AppError, notFound } from '../../platform/errors.js';
import { definedOnly, type Patch } from '../../platform/patch.js';
import { newId } from '../../platform/ids.js';
import { FleetRepository } from './fleet.repository.js';

@Injectable()
export class FleetService {
  constructor(private readonly repo: FleetRepository) {}

  async requireVehicle(tx: TenantTx, id: string): Promise<Vehicle> {
    const vehicle = await this.repo.findVehicle(tx, id);
    if (!vehicle) throw notFound('Vehicle');
    return vehicle;
  }

  async createVehicle(
    tx: TenantTx,
    input: {
      registrationNo: string;
      make: string;
      model: string;
      year?: number | undefined;
      fuelType: FuelType;
      vehicleModelId?: string | undefined;
      lastOdometerKm?: number | undefined;
    },
  ): Promise<Vehicle> {
    const duplicate = await tx.vehicle.count({
      where: { orgId: tx.orgId, registrationNo: input.registrationNo },
    });
    if (duplicate)
      throw new AppError('CONFLICT', `${input.registrationNo} is already in your fleet`);
    return this.repo.createVehicle(tx, {
      id: newId(),
      registrationNo: input.registrationNo,
      make: input.make,
      model: input.model,
      year: input.year ?? null,
      fuelType: input.fuelType,
      vehicleModelId: input.vehicleModelId ?? null,
      lastOdometerKm: input.lastOdometerKm ?? null,
    });
  }

  async updateVehicle(
    tx: TenantTx,
    id: string,
    patch: Patch<Omit<Vehicle, 'id' | 'createdAt'>>,
  ): Promise<Vehicle> {
    await this.requireVehicle(tx, id);
    await this.repo.updateVehicle(tx, id, definedOnly(patch));
    return this.requireVehicle(tx, id);
  }

  async requireDriver(tx: TenantTx, id: string): Promise<Driver> {
    const driver = await this.repo.findDriver(tx, id);
    if (!driver) throw notFound('Driver');
    return driver;
  }

  /**
   * Invites a driver by phone. The user is created if new; an existing member (e.g.
   * a manager who also drives) gains the driver role. The membership stays
   * 'invited' until their first sign-in.
   */
  async inviteDriver(tx: TenantTx, input: { name: string; phone: string }): Promise<Driver> {
    const user = await tx.user.upsert({
      where: { phoneE164: input.phone },
      update: {},
      create: { id: newId(), phoneE164: input.phone, name: input.name },
    });
    if (!user.name) await tx.user.update({ where: { id: user.id }, data: { name: input.name } });

    let membership = await tx.membership.findUnique({
      where: { orgId_userId: { orgId: tx.orgId, userId: user.id } },
    });
    if (!membership) {
      membership = await tx.membership.create({
        data: {
          id: newId(),
          orgId: tx.orgId,
          userId: user.id,
          roles: ['driver'],
          status: 'invited',
        },
      });
    } else if (!membership.roles.includes('driver')) {
      membership = await tx.membership.update({
        where: { id: membership.id },
        data: { roles: [...membership.roles, 'driver'] },
      });
    }
    if (await tx.driver.count({ where: { membershipId: membership.id } })) {
      throw new AppError('CONFLICT', `${input.phone} is already a driver in this organization`);
    }
    const id = newId();
    await tx.driver.create({
      data: { id, orgId: tx.orgId, membershipId: membership.id, userId: user.id, name: input.name },
    });
    return this.requireDriver(tx, id);
  }

  async updateDriver(
    tx: TenantTx,
    id: string,
    patch: Patch<{ name: string; status: 'active' | 'inactive' }>,
  ): Promise<Driver> {
    await this.requireDriver(tx, id);
    await this.repo.updateDriver(tx, id, definedOnly(patch));
    return this.requireDriver(tx, id);
  }

  async setDriverPayRule(tx: TenantTx, id: string, payRule: PayRule | null): Promise<Driver> {
    await this.requireDriver(tx, id);
    await tx.driver.updateMany({
      where: { id, orgId: tx.orgId },
      data: { payRule: payRule ?? Prisma.DbNull },
    });
    return this.requireDriver(tx, id);
  }
}
