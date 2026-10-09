import { Global, Module } from '@nestjs/common';
import { AlertsRepository } from './alerts.repository.js';
import { ReviewItemsRepository } from './review-items.repository.js';

// Global so every module that detects a problem can raise an alert or review item.
@Global()
@Module({
  providers: [AlertsRepository, ReviewItemsRepository],
  exports: [AlertsRepository, ReviewItemsRepository],
})
export class AlertsModule {}
