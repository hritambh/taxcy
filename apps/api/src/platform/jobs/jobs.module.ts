import { Global, Module } from '@nestjs/common';
import { DiscoveryModule } from '@nestjs/core';
import { JobDispatcher } from './job-dispatcher.js';
import { OutboxRelay } from './outbox-relay.js';

@Global()
@Module({
  imports: [DiscoveryModule],
  providers: [JobDispatcher, OutboxRelay],
  exports: [JobDispatcher, OutboxRelay],
})
export class JobsModule {}
