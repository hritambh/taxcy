import { createParamDecorator, type ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
import { AppError } from '../../platform/errors.js';

/** The validated Idempotency-Key header (IdempotencyInterceptor rejects requests without one). */
export const IdempotencyKey = createParamDecorator(
  (_data: unknown, context: ExecutionContext): string => {
    const key = context.switchToHttp().getRequest<Request>().headers['idempotency-key'];
    if (typeof key !== 'string')
      throw new AppError('IDEMPOTENCY_KEY_REQUIRED', 'Send a UUID in the Idempotency-Key header');
    return key;
  },
);
