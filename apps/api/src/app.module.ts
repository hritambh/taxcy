import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR, DiscoveryModule } from '@nestjs/core';
import { LoggerModule } from 'nestjs-pino';
import { HealthModule } from './modules/health/health.module.js';
import { IdentityModule } from './modules/identity/identity.module.js';
import { APP_CONFIG, type AppConfig } from './platform/config.js';
import { AuthGuard } from './platform/http/auth.guard.js';
import { ErrorFilter } from './platform/http/error.filter.js';
import { ContractResponseInterceptor } from './platform/http/response.interceptor.js';
import { loggerParams } from './platform/logging.js';
import { PlatformModule } from './platform/platform.module.js';

@Module({
  imports: [
    PlatformModule,
    DiscoveryModule,
    LoggerModule.forRootAsync({
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) => loggerParams(config),
    }),
    HealthModule,
    IdentityModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_INTERCEPTOR, useClass: ContractResponseInterceptor },
    { provide: APP_FILTER, useClass: ErrorFilter },
  ],
})
export class AppModule {}
