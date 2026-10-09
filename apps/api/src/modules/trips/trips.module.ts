import { Module } from '@nestjs/common';
import { MediaModule } from '../media/media.module.js';
import { TripsController } from './trips.controller.js';
import { TripsRepository } from './trips.repository.js';
import { TripsService } from './trips.service.js';

@Module({
  imports: [MediaModule],
  controllers: [TripsController],
  providers: [TripsRepository, TripsService],
  exports: [TripsRepository, TripsService],
})
export class TripsModule {}
