import { DiscoveryService } from '@nestjs/core';
import type { INestApplication } from '@nestjs/common';
import type { RouteDef } from '@taxcy/contracts';
import { prototypeMethods } from '../methods.js';
import { ROUTE_CONTRACT } from './route.js';

const key = (r: RouteDef) => `${r.method} ${r.path}`;

/** Fails startup unless every contract has exactly one handler and every handler has a contract. */
export function assertRoutesBound(app: INestApplication, contracts: readonly RouteDef[]): void {
  const bound = new Map<string, string>();
  for (const wrapper of app.get(DiscoveryService).getControllers()) {
    const instance: unknown = wrapper.instance;
    if (typeof instance !== 'object' || instance === null) continue;
    for (const [name, handler] of prototypeMethods(instance)) {
      const contract = Reflect.getMetadata(ROUTE_CONTRACT, handler) as RouteDef | undefined;
      if (!contract) continue;
      const k = key(contract);
      const where = `${wrapper.name}.${name}`;
      const existing = bound.get(k);
      if (existing) throw new Error(`Route ${k} is bound twice: ${existing} and ${where}`);
      bound.set(k, where);
    }
  }
  const missing = contracts.map(key).filter((k) => !bound.has(k));
  const unknown = [...bound.keys()].filter((k) => !contracts.some((c) => key(c) === k));
  if (missing.length || unknown.length) {
    throw new Error(
      [
        missing.length ? `Contracts without a handler: ${missing.join(', ')}` : '',
        unknown.length ? `Handlers whose contract is not in allRoutes: ${unknown.join(', ')}` : '',
      ]
        .filter(Boolean)
        .join('\n'),
    );
  }
}
