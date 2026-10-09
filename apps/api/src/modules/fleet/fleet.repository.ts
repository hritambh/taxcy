import { Injectable } from '@nestjs/common';
import { PayRule, type Driver, type FuelType, type Vehicle } from '@taxcy/contracts';
import type { Prisma, TenantTx } from '@taxcy/db';

const vehicleSelect = {
  id: true,
  registrationNo: true,
  make: true,
  model: true,
  year: true,
  fuelType: true,
  vehicleModelId: true,
  lastOdometerKm: true,
  status: true,
  createdAt: true,
} as const;

const driverInclude = {
  membership: { select: { status: true, user: { select: { phoneE164: true } } } },
} as const;

type DriverRow = Prisma.DriverGetPayload<{ include: typeof driverInclude }>;

function toVehicle(row: Prisma.VehicleGetPayload<{ select: typeof vehicleSelect }>): Vehicle {
  return { ...row, status: row.status === 'inactive' ? 'inactive' : 'active' };
}

function toDriver(row: DriverRow): Driver {
  const membershipStatus = row.membership.status;
  return {
    id: row.id,
    userId: row.userId,
    name: row.name,
    phone: row.membership.user.phoneE164,
    status: row.status === 'inactive' ? 'inactive' : 'active',
    membershipStatus:
      membershipStatus === 'invited' || membershipStatus === 'suspended'
        ? membershipStatus
        : 'active',
    payRule: row.payRule === null ? null : PayRule.parse(row.payRule),
    createdAt: row.createdAt,
  };
}

@Injectable()
export class FleetRepository {
  async listVehicles(tx: TenantTx, status?: 'active' | 'inactive'): Promise<Vehicle[]> {
    const rows = await tx.vehicle.findMany({
      where: { orgId: tx.orgId, ...(status ? { status } : {}) },
      select: vehicleSelect,
      orderBy: { registrationNo: 'asc' },
    });
    return rows.map(toVehicle);
  }

  async findVehicle(tx: TenantTx, id: string): Promise<Vehicle | null> {
    const row = await tx.vehicle.findFirst({
      where: { id, orgId: tx.orgId },
      select: vehicleSelect,
    });
    return row ? toVehicle(row) : null;
  }

  async createVehicle(
    tx: TenantTx,
    data: {
      id: string;
      registrationNo: string;
      make: string;
      model: string;
      year: number | null;
      fuelType: FuelType;
      vehicleModelId: string | null;
      lastOdometerKm: number | null;
    },
  ): Promise<Vehicle> {
    return toVehicle(
      await tx.vehicle.create({ data: { ...data, orgId: tx.orgId }, select: vehicleSelect }),
    );
  }

  async updateVehicle(
    tx: TenantTx,
    id: string,
    data: Prisma.VehicleUpdateManyMutationInput,
  ): Promise<void> {
    await tx.vehicle.updateMany({ where: { id, orgId: tx.orgId }, data });
  }

  async listDrivers(tx: TenantTx, status?: 'active' | 'inactive'): Promise<Driver[]> {
    const rows = await tx.driver.findMany({
      where: { orgId: tx.orgId, ...(status ? { status } : {}) },
      include: driverInclude,
      orderBy: { name: 'asc' },
    });
    return rows.map(toDriver);
  }

  async findDriver(tx: TenantTx, id: string): Promise<Driver | null> {
    const row = await tx.driver.findFirst({
      where: { id, orgId: tx.orgId },
      include: driverInclude,
    });
    return row ? toDriver(row) : null;
  }

  async findDriverByUser(tx: TenantTx, userId: string): Promise<Driver | null> {
    const row = await tx.driver.findFirst({
      where: { userId, orgId: tx.orgId },
      include: driverInclude,
    });
    return row ? toDriver(row) : null;
  }

  async updateDriver(
    tx: TenantTx,
    id: string,
    data: Prisma.DriverUpdateManyMutationInput,
  ): Promise<void> {
    await tx.driver.updateMany({ where: { id, orgId: tx.orgId }, data });
  }
}
