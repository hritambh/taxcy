import { Injectable } from '@nestjs/common';
import { AppError } from './errors.js';
import { RedisService } from './redis.service.js';

export interface Limit {
  /** Redis key identifying the bucket, e.g. otp:phone:+9198…:10m. */
  key: string;
  max: number;
  windowSeconds: number;
}

/** Fixed-window counters in Redis. Throws RATE_LIMITED (with retry-after) when any limit is exceeded. */
@Injectable()
export class RateLimiter {
  constructor(private readonly redis: RedisService) {}

  async consume(limits: Limit[]): Promise<void> {
    const pipeline = this.redis.client.multi();
    for (const limit of limits) {
      pipeline
        .incr(`rl:${limit.key}`)
        .expire(`rl:${limit.key}`, limit.windowSeconds, 'NX')
        .ttl(`rl:${limit.key}`);
    }
    const results = (await pipeline.exec()) ?? [];
    limits.forEach((limit, i) => {
      const count = Number(results[i * 3]?.[1] ?? 0);
      const ttl = Number(results[i * 3 + 2]?.[1] ?? limit.windowSeconds);
      if (count > limit.max) {
        throw new AppError('RATE_LIMITED', 'Too many requests, try again later', {
          retryAfterSeconds: Math.max(ttl, 1),
        });
      }
    });
  }
}
