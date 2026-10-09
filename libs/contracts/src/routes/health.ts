import { z } from 'zod';
import { access, defineRoute } from '../http.js';

const CheckStatus = z.enum(['ok', 'error']);

export const healthRoutes = {
  live: defineRoute({
    method: 'GET',
    path: '/health/live',
    summary: 'Process is up',
    tag: 'health',
    access: access.public,
    response: z.object({ status: z.literal('ok') }),
  }),
  ready: defineRoute({
    method: 'GET',
    path: '/health/ready',
    summary: 'Dependencies (Postgres, Redis, S3) are reachable',
    tag: 'health',
    access: access.public,
    response: z.object({
      status: CheckStatus,
      checks: z.object({ postgres: CheckStatus, redis: CheckStatus, s3: CheckStatus }),
    }),
  }),
};
