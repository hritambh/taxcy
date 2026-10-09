import { Module } from '@nestjs/common';
import { FleetModule } from '../fleet/fleet.module.js';
import { TripsModule } from '../trips/trips.module.js';
import { CollectionsService } from './collections.service.js';
import { InboxService } from './inbox.service.js';
import { MoneyController } from './money.controller.js';
import { SettlementsService } from './settlements.service.js';

@Module({
  imports: [FleetModule, TripsModule],
  controllers: [MoneyController],
  providers: [CollectionsService, SettlementsService, InboxService],
})
export class MoneyModule {}
