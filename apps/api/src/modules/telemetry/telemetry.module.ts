import { Module } from '@nestjs/common';
import { FleetModule } from '../fleet/fleet.module.js';
import { TelemetryController } from './telemetry.controller.js';
import { TelemetryRepository } from './telemetry.repository.js';
import { TelemetryService } from './telemetry.service.js';

@Module({
  imports: [FleetModule],
  controllers: [TelemetryController],
  providers: [TelemetryRepository, TelemetryService],
})
export class TelemetryModule {}
