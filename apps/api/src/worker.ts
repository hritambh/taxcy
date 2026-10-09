// Entry point for apps/workers: the same modules as the HTTP app, without HTTP.
import 'reflect-metadata';
import { Module, type INestApplicationContext } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { LoggerModule, Logger } from 'nestjs-pino';
import { DOMAIN_MODULES } from './domain-modules.js';
import { APP_CONFIG, type AppConfig } from './platform/config.js';
import { JobsModule } from './platform/jobs/jobs.module.js';
import { loggerParams } from './platform/logging.js';
import { PlatformModule } from './platform/platform.module.js';

@Module({
  imports: [
    PlatformModule,
    JobsModule,
    LoggerModule.forRootAsync({
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) => loggerParams(config),
    }),
    ...DOMAIN_MODULES,
  ],
})
class WorkerModule {}

export async function createWorkerContext(): Promise<INestApplicationContext> {
  const context = await NestFactory.createApplicationContext(WorkerModule, { bufferLogs: true });
  context.useLogger(context.get(Logger));
  context.enableShutdownHooks();
  return context;
}

export { APP_CONFIG, type AppConfig } from './platform/config.js';
export { JobDispatcher } from './platform/jobs/job-dispatcher.js';
export { OutboxRelay } from './platform/jobs/outbox-relay.js';
export { queueFor, SCHEDULES, type JobEvent } from './platform/jobs/on-job.js';
