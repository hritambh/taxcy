import { randomUUID } from 'node:crypto';
import type { Params } from 'nestjs-pino';
import type { AppConfig } from './config.js';

const REQUEST_ID = /^[\w.-]{1,128}$/;

export function loggerParams(config: AppConfig): Params {
  return {
    pinoHttp: {
      level: config.LOG_LEVEL,
      // Honour an incoming X-Request-Id (from a proxy or client) and always echo it back.
      genReqId: (req, res) => {
        const incoming = req.headers['x-request-id'];
        const id =
          typeof incoming === 'string' && REQUEST_ID.test(incoming) ? incoming : randomUUID();
        res.setHeader('X-Request-Id', id);
        return id;
      },
      customProps: (req) => {
        const auth = (req as { auth?: { userId: string; orgId: string | null } }).auth;
        return auth ? { userId: auth.userId, orgId: auth.orgId } : {};
      },
      redact: {
        paths: [
          'req.headers.authorization',
          'req.headers.cookie',
          'req.body.code',
          'req.body.refreshToken',
        ],
        censor: '[redacted]',
      },
      ...(config.NODE_ENV === 'development'
        ? {
            transport: {
              target: 'pino-pretty',
              options: { singleLine: true, translateTime: 'SYS:HH:MM:ss' },
            },
          }
        : {}),
      autoLogging: { ignore: (req) => req.url?.startsWith('/v1/health') ?? false },
    },
  };
}
