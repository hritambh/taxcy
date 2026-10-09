import { Controller } from '@nestjs/common';
import { healthRoutes, type RouteOutput } from '@taxcy/contracts';
import { Db } from '../../platform/prisma.service.js';
import { RedisService } from '../../platform/redis.service.js';
import { S3Service } from '../../platform/s3.service.js';
import { Route } from '../../platform/http/route.js';

async function check(probe: () => Promise<unknown>): Promise<'ok' | 'error'> {
  try {
    await probe();
    return 'ok';
  } catch {
    return 'error';
  }
}

@Controller()
export class HealthController {
  constructor(
    private readonly db: Db,
    private readonly redis: RedisService,
    private readonly s3: S3Service,
  ) {}

  @Route(healthRoutes.live)
  live(): RouteOutput<typeof healthRoutes.live> {
    return { status: 'ok' };
  }

  @Route(healthRoutes.ready)
  async ready(): Promise<RouteOutput<typeof healthRoutes.ready>> {
    const [postgres, redis, s3] = await Promise.all([
      check(() => this.db.client.$queryRaw`SELECT 1`),
      check(() => this.redis.client.ping()),
      check(() => this.s3.ping()),
    ]);
    const healthy = postgres === 'ok' && redis === 'ok' && s3 === 'ok';
    return { status: healthy ? 'ok' : 'error', checks: { postgres, redis, s3 } };
  }
}
