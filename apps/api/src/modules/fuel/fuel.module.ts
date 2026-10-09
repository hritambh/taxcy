import { Module } from '@nestjs/common';
import { FleetModule } from '../fleet/fleet.module.js';
import { MediaModule } from '../media/media.module.js';
import { FuelAuditJob } from './fuel-audit.job.js';
import { FuelAuditService } from './fuel-audit.service.js';
import { FuelController } from './fuel.controller.js';
import { FuelService } from './fuel.service.js';

@Module({
  imports: [MediaModule, FleetModule],
  controllers: [FuelController],
  providers: [FuelService, FuelAuditService, FuelAuditJob],
  exports: [FuelAuditService],
})
export class FuelModule {}
