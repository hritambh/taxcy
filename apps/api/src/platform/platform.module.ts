import { Global, Module } from '@nestjs/common';
import { AccessTokens } from './auth/tokens.js';
import { APP_CONFIG, loadConfig } from './config.js';
import { Db } from './prisma.service.js';
import { RedisService } from './redis.service.js';
import { S3Service } from './s3.service.js';

@Global()
@Module({
  providers: [
    { provide: APP_CONFIG, useFactory: () => loadConfig() },
    Db,
    RedisService,
    S3Service,
    AccessTokens,
  ],
  exports: [APP_CONFIG, Db, RedisService, S3Service, AccessTokens],
})
export class PlatformModule {}
