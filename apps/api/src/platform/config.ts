import { z } from 'zod';

// Empty strings in .env mean "not set".
const optional = <T extends z.ZodType>(schema: T) =>
  z.preprocess((v) => (v === '' ? undefined : v), schema.optional());

const Env = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  CORS_ORIGINS: z
    .string()
    .default('http://localhost:5173,http://localhost:5174')
    .transform((v) =>
      v
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean),
    ),

  DATABASE_URL: z.url(),
  REDIS_URL: z.url(),

  S3_ENDPOINT: z.url(),
  S3_PUBLIC_ENDPOINT: optional(z.url()),
  S3_REGION: z.string().min(1),
  S3_BUCKET: z.string().min(1),
  S3_ACCESS_KEY_ID: z.string().min(1),
  S3_SECRET_ACCESS_KEY: z.string().min(1),
  S3_UPLOAD_URL_TTL_SECONDS: z.coerce.number().int().positive().default(600),

  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET must be at least 32 characters'),
  JWT_ACCESS_TTL_SECONDS: z.coerce.number().int().positive().default(900),
  JWT_REFRESH_TTL_DAYS: z.coerce.number().int().positive().default(30),

  OTP_TTL_SECONDS: z.coerce.number().int().positive().default(300),
  OTP_MAX_ATTEMPTS: z.coerce.number().int().positive().default(5),
  /** OTP requests allowed per client IP per hour (shared networks, e.g. a depot's Wi-Fi, need headroom). */
  OTP_IP_LIMIT_PER_HOUR: z.coerce.number().int().positive().default(30),
  SMS_PROVIDER: z.enum(['console']).default('console'),
  OCR_PROVIDER: z.enum(['stub']).default('stub'),

  SENTRY_DSN: optional(z.url()),
});

export type AppConfig = z.infer<typeof Env>;

/** Injection token for the validated config. */
export const APP_CONFIG = Symbol('APP_CONFIG');

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const result = Env.safeParse(env);
  if (!result.success) {
    const problems = result.error.issues
      .map((i) => `  - ${i.path.join('.') || '(root)'}: ${i.message}`)
      .join('\n');
    throw new Error(
      `Invalid environment configuration:\n${problems}\nSee .env.example and docs/development.md.`,
    );
  }
  return result.data;
}
