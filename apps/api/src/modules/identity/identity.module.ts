import { Module } from '@nestjs/common';
import { RateLimiter } from '../../platform/rate-limit.js';
import { AuthController } from './auth.controller.js';
import { IdentityRepository } from './identity.repository.js';
import { OrgsService } from './orgs.service.js';
import { OtpService } from './otp.service.js';
import { SessionService } from './session.service.js';
import { ConsoleSmsProvider, SMS_PROVIDER } from './sms.provider.js';

@Module({
  controllers: [AuthController],
  providers: [
    { provide: SMS_PROVIDER, useClass: ConsoleSmsProvider },
    RateLimiter,
    OtpService,
    IdentityRepository,
    SessionService,
    OrgsService,
  ],
})
export class IdentityModule {}
