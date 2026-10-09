import {
  applyDecorators,
  createParamDecorator,
  Delete,
  Get,
  HttpCode,
  Patch,
  Post,
  Put,
  SetMetadata,
  type ExecutionContext,
} from '@nestjs/common';
import { toExpressPath, type RouteDef, type RouteInput } from '@taxcy/contracts';
import type { Request } from 'express';
import type { z } from 'zod';
import type { AuthContext, TenantAuth } from '../auth/auth-context.js';
import { AppError } from '../errors.js';

export const ROUTE_CONTRACT = Symbol('ROUTE_CONTRACT');

const METHOD_DECORATORS = { GET: Get, POST: Post, PUT: Put, PATCH: Patch, DELETE: Delete } as const;

/**
 * Binds a handler to a route contract from @taxcy/contracts: HTTP method, path,
 * success status, access rules (enforced by AuthGuard) and input/output schemas
 * (enforced by @Input() and ContractResponseInterceptor).
 */
export function Route(contract: RouteDef): MethodDecorator {
  return applyDecorators(
    METHOD_DECORATORS[contract.method](toExpressPath(contract.path)),
    HttpCode(contract.status ?? 200),
    SetMetadata(ROUTE_CONTRACT, contract),
  );
}

export function contractOf(context: ExecutionContext): RouteDef | undefined {
  return Reflect.getMetadata(ROUTE_CONTRACT, context.getHandler()) as RouteDef | undefined;
}

function parsePart(schema: z.ZodType | undefined, value: unknown, part: string): unknown {
  if (!schema) return undefined;
  const result = schema.safeParse(value);
  if (!result.success) {
    throw new AppError('VALIDATION_FAILED', `Invalid request ${part}`, {
      part,
      issues: result.error.issues.map((i) => ({
        path: i.path.join('.'),
        message: i.message,
        code: i.code,
      })),
    });
  }
  return result.data;
}

/** The handler's validated params, query and body, typed from its contract. */
export const Input = createParamDecorator(
  (_data: unknown, context: ExecutionContext): RouteInput<RouteDef> => {
    const contract = contractOf(context);
    if (!contract) throw new Error('@Input() used on a handler without @Route()');
    const req = context.switchToHttp().getRequest<Request>();
    return {
      params: parsePart(contract.params, req.params, 'params'),
      query: parsePart(contract.query, req.query, 'query'),
      body: parsePart(contract.body, req.body, 'body'),
    };
  },
);

/** The caller's auth context (any signed-in route). */
export const Auth = createParamDecorator(
  (_data: unknown, context: ExecutionContext): AuthContext => {
    const auth = context.switchToHttp().getRequest<Request>().auth;
    if (!auth) throw new AppError('UNAUTHENTICATED', 'Not signed in');
    return auth;
  },
);

/** The caller's auth context on routes that require an active org. */
export const Tenant = createParamDecorator(
  (_data: unknown, context: ExecutionContext): TenantAuth => {
    const auth = context.switchToHttp().getRequest<Request>().auth;
    if (!auth) throw new AppError('UNAUTHENTICATED', 'Not signed in');
    if (!auth.orgId) throw new AppError('NO_ACTIVE_ORG', 'Select an organization first');
    return { ...auth, orgId: auth.orgId };
  },
);
