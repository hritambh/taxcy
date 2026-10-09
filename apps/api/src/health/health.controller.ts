import { Controller, Get } from '@nestjs/common';

// Readiness checks (Postgres, Redis, S3) are added in M0.2.
@Controller('health')
export class HealthController {
  @Get('live')
  live(): { status: 'ok' } {
    return { status: 'ok' };
  }
}
