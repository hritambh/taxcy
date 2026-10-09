import { Controller } from '@nestjs/common';
import { fleetRoutes as r, type RouteInput, type RouteOutput } from '@taxcy/contracts';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { Input, Route, Tenant } from '../../platform/http/route.js';
import { Db } from '../../platform/prisma.service.js';
import { DocumentsService } from './documents.service.js';
import { FleetRepository } from './fleet.repository.js';
import { FleetService } from './fleet.service.js';
import { SettingsService } from './settings.service.js';

@Controller()
export class FleetController {
  constructor(
    private readonly db: Db,
    private readonly fleet: FleetService,
    private readonly repo: FleetRepository,
    private readonly documents: DocumentsService,
    private readonly settings: SettingsService,
  ) {}

  @Route(r.listVehicles)
  listVehicles(
    @Tenant() a: TenantAuth,
    @Input() { query }: RouteInput<typeof r.listVehicles>,
  ): Promise<RouteOutput<typeof r.listVehicles>> {
    return this.db.tenant(a.orgId, (tx) => this.repo.listVehicles(tx, query.status));
  }

  @Route(r.createVehicle)
  createVehicle(
    @Tenant() a: TenantAuth,
    @Input() { body }: RouteInput<typeof r.createVehicle>,
  ): Promise<RouteOutput<typeof r.createVehicle>> {
    return this.db.tenant(a.orgId, (tx) => this.fleet.createVehicle(tx, body));
  }

  @Route(r.getVehicle)
  getVehicle(
    @Tenant() a: TenantAuth,
    @Input() { params }: RouteInput<typeof r.getVehicle>,
  ): Promise<RouteOutput<typeof r.getVehicle>> {
    return this.db.tenant(a.orgId, (tx) => this.fleet.requireVehicle(tx, params.id));
  }

  @Route(r.updateVehicle)
  updateVehicle(
    @Tenant() a: TenantAuth,
    @Input() { params, body }: RouteInput<typeof r.updateVehicle>,
  ): Promise<RouteOutput<typeof r.updateVehicle>> {
    return this.db.tenant(a.orgId, (tx) => this.fleet.updateVehicle(tx, params.id, body));
  }

  @Route(r.listVehicleModels)
  listVehicleModels(@Tenant() a: TenantAuth): Promise<RouteOutput<typeof r.listVehicleModels>> {
    return this.db.tenant(a.orgId, (tx) =>
      tx.vehicleModel.findMany({
        where: { OR: [{ orgId: null }, { orgId: tx.orgId }] },
        select: { id: true, make: true, model: true, fuelType: true },
        orderBy: [{ make: 'asc' }, { model: 'asc' }],
      }),
    );
  }

  @Route(r.listDrivers)
  listDrivers(
    @Tenant() a: TenantAuth,
    @Input() { query }: RouteInput<typeof r.listDrivers>,
  ): Promise<RouteOutput<typeof r.listDrivers>> {
    return this.db.tenant(a.orgId, (tx) => this.repo.listDrivers(tx, query.status));
  }

  @Route(r.inviteDriver)
  inviteDriver(
    @Tenant() a: TenantAuth,
    @Input() { body }: RouteInput<typeof r.inviteDriver>,
  ): Promise<RouteOutput<typeof r.inviteDriver>> {
    return this.db.tenant(a.orgId, (tx) => this.fleet.inviteDriver(tx, body));
  }

  @Route(r.getDriver)
  getDriver(
    @Tenant() a: TenantAuth,
    @Input() { params }: RouteInput<typeof r.getDriver>,
  ): Promise<RouteOutput<typeof r.getDriver>> {
    return this.db.tenant(a.orgId, (tx) => this.fleet.requireDriver(tx, params.id));
  }

  @Route(r.updateDriver)
  updateDriver(
    @Tenant() a: TenantAuth,
    @Input() { params, body }: RouteInput<typeof r.updateDriver>,
  ): Promise<RouteOutput<typeof r.updateDriver>> {
    return this.db.tenant(a.orgId, (tx) => this.fleet.updateDriver(tx, params.id, body));
  }

  @Route(r.setDriverPayRule)
  setDriverPayRule(
    @Tenant() a: TenantAuth,
    @Input() { params, body }: RouteInput<typeof r.setDriverPayRule>,
  ): Promise<RouteOutput<typeof r.setDriverPayRule>> {
    return this.db.tenant(a.orgId, (tx) =>
      this.fleet.setDriverPayRule(tx, params.id, body.payRule),
    );
  }

  @Route(r.listDocuments)
  listDocuments(
    @Tenant() a: TenantAuth,
    @Input() { query }: RouteInput<typeof r.listDocuments>,
  ): Promise<RouteOutput<typeof r.listDocuments>> {
    return this.db.tenant(a.orgId, (tx) => this.documents.list(tx, query));
  }

  @Route(r.createDocument)
  createDocument(
    @Tenant() a: TenantAuth,
    @Input() { body }: RouteInput<typeof r.createDocument>,
  ): Promise<RouteOutput<typeof r.createDocument>> {
    return this.db.tenant(a.orgId, (tx) => this.documents.create(tx, body));
  }

  @Route(r.renewDocument)
  renewDocument(
    @Tenant() a: TenantAuth,
    @Input() { params, body }: RouteInput<typeof r.renewDocument>,
  ): Promise<RouteOutput<typeof r.renewDocument>> {
    return this.db.tenant(a.orgId, (tx) => this.documents.renew(tx, params.id, body));
  }

  @Route(r.getAuditSettings)
  async getAuditSettings(@Tenant() a: TenantAuth): Promise<RouteOutput<typeof r.getAuditSettings>> {
    return (await this.db.tenant(a.orgId, (tx) => this.settings.get(tx))).audit;
  }

  @Route(r.updateAuditSettings)
  updateAuditSettings(
    @Tenant() a: TenantAuth,
    @Input() { body }: RouteInput<typeof r.updateAuditSettings>,
  ): Promise<RouteOutput<typeof r.updateAuditSettings>> {
    return this.db.tenant(a.orgId, (tx) => this.settings.updateAudit(tx, body));
  }

  @Route(r.getDriverPay)
  async getDriverPay(@Tenant() a: TenantAuth): Promise<RouteOutput<typeof r.getDriverPay>> {
    return (await this.db.tenant(a.orgId, (tx) => this.settings.get(tx))).payRule;
  }

  @Route(r.updateDriverPay)
  updateDriverPay(
    @Tenant() a: TenantAuth,
    @Input() { body }: RouteInput<typeof r.updateDriverPay>,
  ): Promise<RouteOutput<typeof r.updateDriverPay>> {
    return this.db.tenant(a.orgId, (tx) => this.settings.updatePayRule(tx, body));
  }
}
