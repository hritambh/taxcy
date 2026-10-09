import {
  Injectable,
  type CallHandler,
  type ExecutionContext,
  type NestInterceptor,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { createHash } from 'node:crypto';
import { from, mergeMap, of, type Observable } from 'rxjs';
import { z } from 'zod';
import { AppError } from '../errors.js';
import { Db } from '../prisma.service.js';
import { contractOf } from './route.js';

const IdempotencyKey = z.uuid();

/**
 * For contracts marked `idempotencyKey: true`: the first successful response for a
 * key is stored; a replay with the same key and body returns it verbatim (with
 * Idempotent-Replay: true); the same key with a different body is a 409. Failed
 * requests are not stored, so a retry re-executes (commands are themselves safe
 * to repeat, e.g. trip events use the key as their primary key).
 */
@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(private readonly db: Db) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const contract = contractOf(context);
    if (!contract?.idempotencyKey) return next.handle();

    const req = context.switchToHttp().getRequest<Request>();
    const res = context.switchToHttp().getResponse<Response>();
    const auth = req.auth;
    if (!auth?.orgId) throw new AppError('NO_ACTIVE_ORG', 'Select an organization first');
    const orgId = auth.orgId;
    const parsedKey = IdempotencyKey.safeParse(req.headers['idempotency-key']);
    if (!parsedKey.success) {
      throw new AppError('IDEMPOTENCY_KEY_REQUIRED', 'Send a UUID in the Idempotency-Key header');
    }
    const key = parsedKey.data;
    const route = `${contract.method} ${contract.path}`;
    const requestHash = createHash('sha256')
      .update(JSON.stringify({ route, params: req.params, body: req.body as unknown }))
      .digest('hex');

    return from(
      this.db.tenant(orgId, (tx) => tx.idempotencyKey.findUnique({ where: { key } })),
    ).pipe(
      mergeMap((stored) => {
        if (stored) {
          if (
            stored.userId !== auth.userId ||
            stored.route !== route ||
            stored.requestHash !== requestHash
          ) {
            throw new AppError(
              'IDEMPOTENCY_CONFLICT',
              'This Idempotency-Key was already used for a different request',
            );
          }
          res.status(stored.responseStatus).setHeader('Idempotent-Replay', 'true');
          return of(stored.responseBody);
        }
        return next.handle().pipe(
          mergeMap(async (body: unknown) => {
            await this.db.tenant(orgId, (tx) =>
              tx.idempotencyKey.createMany({
                data: {
                  key,
                  orgId,
                  userId: auth.userId,
                  route,
                  requestHash,
                  responseStatus: contract.status ?? 200,
                  responseBody: body ?? {},
                },
                skipDuplicates: true,
              }),
            );
            return body;
          }),
        );
      }),
    );
  }
}
