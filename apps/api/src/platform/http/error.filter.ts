import {
  Catch,
  HttpException,
  Logger,
  type ArgumentsHost,
  type ExceptionFilter,
} from '@nestjs/common';
import * as Sentry from '@sentry/nestjs';
import type { ErrorBody, ErrorCode } from '@taxcy/contracts';
import type { Request, Response } from 'express';
import { AppError } from '../errors.js';

interface PgLikeError {
  code?: string;
  constraint?: string;
  message?: string;
}

/** Postgres errors that represent client-caused conflicts, surfaced through Prisma. */
function fromDatabase(error: unknown): AppError | undefined {
  const pg = findCause(error);
  if (!pg?.code) return undefined;
  if (pg.code === '23P01') {
    // Prisma's driver adapter keeps the constraint name only in the message text.
    const constraint = pg.constraint ?? /constraint "([^"]+)"/.exec(pg.message ?? '')?.[1] ?? '';
    if (constraint.includes('vehicle'))
      return new AppError('VEHICLE_BUSY', 'Vehicle is already booked for an overlapping time');
    if (constraint.includes('driver'))
      return new AppError('DRIVER_BUSY', 'Driver is already booked for an overlapping time');
    return new AppError('CONFLICT', 'Overlaps an existing booking');
  }
  if (pg.code === '23505')
    return new AppError('CONFLICT', 'A record with these values already exists');
  return undefined;
}

function findCause(error: unknown, depth = 0): PgLikeError | undefined {
  if (depth > 5 || typeof error !== 'object' || error === null) return undefined;
  const candidate = error as PgLikeError & {
    cause?: unknown;
    meta?: { driverAdapterError?: { cause?: unknown } };
  };
  // A Postgres SQLSTATE (e.g. 23P01) starts with a digit; Prisma's own codes (P2039) don't.
  if (typeof candidate.code === 'string' && /^[0-9][0-9A-Z]{4}$/.test(candidate.code))
    return candidate;
  return (
    findCause(candidate.cause, depth + 1) ??
    findCause(candidate.meta?.driverAdapterError?.cause, depth + 1)
  );
}

@Catch()
export class ErrorFilter implements ExceptionFilter {
  private readonly logger = new Logger('ErrorFilter');

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const req = http.getRequest<Request>();
    const res = http.getResponse<Response>();
    const requestId = typeof req.id === 'string' ? req.id : undefined;

    let status: number;
    let code: ErrorCode;
    let message: string;
    let details: unknown;

    const app = exception instanceof AppError ? exception : fromDatabase(exception);
    if (app) {
      ({ status, code, message, details } = app);
    } else if (exception instanceof HttpException) {
      status = exception.getStatus();
      code = status === 404 ? 'NOT_FOUND' : status === 429 ? 'RATE_LIMITED' : 'VALIDATION_FAILED';
      message = exception.message;
    } else {
      status = 500;
      code = 'INTERNAL';
      message = 'Something went wrong';
      this.logger.error(exception instanceof Error ? exception : new Error(String(exception)));
      Sentry.captureException(exception);
    }

    const body: ErrorBody = {
      error: {
        code,
        message,
        ...(details === undefined ? {} : { details }),
        ...(requestId ? { requestId } : {}),
      },
    };
    res.status(status).json(body);
  }
}
