import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR, DiscoveryModule } from '@nestjs/core';
import { LoggerModule } from 'nestjs-pino';
import { DOMAIN_MODULES } from './domain-modules.js';
import { APP_CONFIG, type AppConfig } from './platform/config.js';
import { AuthGuard } from './platform/http/auth.guard.js';
import { ErrorFilter } from './platform/http/error.filter.js';
import { IdempotencyInterceptor } from './platform/http/idempotency.interceptor.js';
import { ContractResponseInterceptor } from './platform/http/response.interceptor.js';
import { JobsModule } from './platform/jobs/jobs.module.js';
import { loggerParams } from './platform/logging.js';
import { PlatformModule } from './platform/platform.module.js';

@Module({
  imports: [
    PlatformModule,
    DiscoveryModule,
    JobsModule,
    LoggerModule.forRootAsync({
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) => loggerParams(config),
    }),
    ...DOMAIN_MODULES,
  ],
  providers: [
    { provide: APP_GUARD, useClass: AuthGuard },
    // Order matters: idempotency wraps the response encoder, so it stores the encoded body.
    { provide: APP_INTERCEPTOR, useClass: IdempotencyInterceptor },
    { provide: APP_INTERCEPTOR, useClass: ContractResponseInterceptor },
    { provide: APP_FILTER, useClass: ErrorFilter },
  ],
})
export class AppModule {}
