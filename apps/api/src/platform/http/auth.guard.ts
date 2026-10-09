import { Injectable, type CanActivate, type ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
import { AccessTokens } from '../auth/tokens.js';
import { AppError } from '../errors.js';
import { contractOf } from './route.js';

/**
 * Global guard. Every handler must be bound to a contract with @Route(); the
 * contract's `access` decides what's required. Org scoping comes from the token's
 * org claim and is applied by repositories via TenantTx (plus Postgres RLS).
 */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly tokens: AccessTokens) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const contract = contractOf(context);
    if (!contract) {
      throw new Error(
        `Handler ${context.getClass().name}.${context.getHandler().name} has no @Route() contract`,
      );
    }
    if (contract.access.kind === 'public') return true;

    const req = context.switchToHttp().getRequest<Request>();
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      throw new AppError('UNAUTHENTICATED', 'Missing bearer token');
    }
    const auth = await this.tokens.verify(header.slice('Bearer '.length));
    req.auth = auth;

    if (contract.access.kind === 'roles') {
      if (!auth.orgId) throw new AppError('NO_ACTIVE_ORG', 'Select an organization first');
      const allowed = contract.access.roles;
      if (!auth.roles.some((r) => allowed.includes(r))) {
        throw new AppError('FORBIDDEN_ROLE', `Requires one of: ${allowed.join(', ')}`);
      }
    }
    return true;
  }
}
