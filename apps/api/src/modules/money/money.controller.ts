import { Controller } from '@nestjs/common';
import {
  alertRoutes as a,
  moneyRoutes as m,
  type RouteInput,
  type RouteOutput,
} from '@taxcy/contracts';
import type { TenantAuth } from '../../platform/auth/auth-context.js';
import { Input, Route, Tenant } from '../../platform/http/route.js';
import { CollectionsService } from './collections.service.js';
import { InboxService } from './inbox.service.js';
import { SettlementsService } from './settlements.service.js';

@Controller()
export class MoneyController {
  constructor(
    private readonly collections: CollectionsService,
    private readonly settlements: SettlementsService,
    private readonly inbox: InboxService,
  ) {}

  @Route(m.addCollection)
  addCollection(
    @Tenant() t: TenantAuth,
    @Input() { params, body }: RouteInput<typeof m.addCollection>,
  ): Promise<RouteOutput<typeof m.addCollection>> {
    return this.collections.add(t, params.id, body);
  }

  @Route(m.listSettlements)
  listSettlements(
    @Tenant() t: TenantAuth,
    @Input() { query }: RouteInput<typeof m.listSettlements>,
  ): Promise<RouteOutput<typeof m.listSettlements>> {
    return this.settlements.list(t, query.date);
  }

  @Route(m.getSettlement)
  getSettlement(
    @Tenant() t: TenantAuth,
    @Input() { params }: RouteInput<typeof m.getSettlement>,
  ): Promise<RouteOutput<typeof m.getSettlement>> {
    return this.settlements.get(t, params.date, params.driverId);
  }

  @Route(m.settle)
  settle(
    @Tenant() t: TenantAuth,
    @Input() { params }: RouteInput<typeof m.settle>,
  ): Promise<RouteOutput<typeof m.settle>> {
    return this.settlements.settle(t, params.date, params.driverId);
  }

  @Route(a.listAlerts)
  listAlerts(
    @Tenant() t: TenantAuth,
    @Input() { query }: RouteInput<typeof a.listAlerts>,
  ): Promise<RouteOutput<typeof a.listAlerts>> {
    return this.inbox.alerts(t, query);
  }

  @Route(a.alertSummary)
  alertSummary(@Tenant() t: TenantAuth): Promise<RouteOutput<typeof a.alertSummary>> {
    return this.inbox.summary(t);
  }

  @Route(a.updateAlert)
  updateAlert(
    @Tenant() t: TenantAuth,
    @Input() { params, body }: RouteInput<typeof a.updateAlert>,
  ): Promise<RouteOutput<typeof a.updateAlert>> {
    return this.inbox.updateAlert(t, params.id, body);
  }

  @Route(a.listReviewItems)
  listReviewItems(
    @Tenant() t: TenantAuth,
    @Input() { query }: RouteInput<typeof a.listReviewItems>,
  ): Promise<RouteOutput<typeof a.listReviewItems>> {
    return this.inbox.reviewItems(t, query);
  }

  @Route(a.resolveReviewItem)
  resolveReviewItem(
    @Tenant() t: TenantAuth,
    @Input() { params, body }: RouteInput<typeof a.resolveReviewItem>,
  ): Promise<RouteOutput<typeof a.resolveReviewItem>> {
    return this.inbox.resolveReview(t, params.id, body);
  }
}
