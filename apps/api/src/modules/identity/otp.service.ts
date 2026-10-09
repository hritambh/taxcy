import { Inject, Injectable } from '@nestjs/common';
import { createHash, randomInt, timingSafeEqual } from 'node:crypto';
import { z } from 'zod';
import { APP_CONFIG, type AppConfig } from '../../platform/config.js';
import { AppError } from '../../platform/errors.js';
import { RateLimiter } from '../../platform/rate-limit.js';
import { RedisService } from '../../platform/redis.service.js';
import { SMS_PROVIDER, type SmsProvider } from './sms.provider.js';

const Challenge = z.object({ hash: z.string(), attempts: z.number().int() });

const RESEND_AFTER_SECONDS = 30;

@Injectable()
export class OtpService {
  constructor(
    @Inject(APP_CONFIG) private readonly config: AppConfig,
    @Inject(SMS_PROVIDER) private readonly sms: SmsProvider,
    private readonly redis: RedisService,
    private readonly limiter: RateLimiter,
  ) {}

  async request(
    phone: string,
    ip: string,
  ): Promise<{ expiresInSeconds: number; resendAfterSeconds: number }> {
    await this.limiter.consume([
      { key: `otp:resend:${phone}`, max: 1, windowSeconds: RESEND_AFTER_SECONDS },
      { key: `otp:phone:${phone}:10m`, max: 3, windowSeconds: 600 },
      { key: `otp:phone:${phone}:1d`, max: 10, windowSeconds: 86_400 },
      { key: `otp:ip:${ip}:1h`, max: 30, windowSeconds: 3_600 },
    ]);
    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    const challenge: z.infer<typeof Challenge> = { hash: this.hash(phone, code), attempts: 0 };
    await this.redis.client.set(
      this.key(phone),
      JSON.stringify(challenge),
      'EX',
      this.config.OTP_TTL_SECONDS,
    );
    await this.sms.sendOtp(phone, code);
    return {
      expiresInSeconds: this.config.OTP_TTL_SECONDS,
      resendAfterSeconds: RESEND_AFTER_SECONDS,
    };
  }

  /** Consumes the challenge on success. Each wrong guess uses up an attempt. */
  async verify(phone: string, code: string): Promise<void> {
    const key = this.key(phone);
    const raw = await this.redis.client.get(key);
    if (!raw) throw new AppError('OTP_EXPIRED', 'Code expired or not requested; request a new one');
    const challenge = Challenge.parse(JSON.parse(raw));
    if (challenge.attempts >= this.config.OTP_MAX_ATTEMPTS) {
      await this.redis.client.del(key);
      throw new AppError('OTP_EXPIRED', 'Too many wrong attempts; request a new code');
    }
    const expected = Buffer.from(challenge.hash, 'hex');
    const actual = Buffer.from(this.hash(phone, code), 'hex');
    if (!timingSafeEqual(expected, actual)) {
      const ttl = await this.redis.client.ttl(key);
      await this.redis.client.set(
        key,
        JSON.stringify({ ...challenge, attempts: challenge.attempts + 1 }),
        'EX',
        Math.max(ttl, 1),
      );
      throw new AppError('OTP_INVALID', 'Incorrect code', {
        attemptsLeft: this.config.OTP_MAX_ATTEMPTS - challenge.attempts - 1,
      });
    }
    await this.redis.client.del(key);
  }

  private key(phone: string): string {
    return `otp:challenge:${phone}`;
  }

  private hash(phone: string, code: string): string {
    // Keyed so a Redis dump alone can't be brute-forced offline.
    return createHash('sha256')
      .update(`${this.config.JWT_ACCESS_SECRET}:${phone}:${code}`)
      .digest('hex');
  }
}
