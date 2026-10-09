import type { RouteDef } from '../http.js';
import { fleetRoutes } from './fleet.js';
import { healthRoutes } from './health.js';
import { identityRoutes } from './identity.js';
import { mediaRoutes } from './media.js';

export * from './fleet.js';
export { healthRoutes } from './health.js';
export * from './identity.js';
export * from './media.js';

const groups: readonly Record<string, RouteDef>[] = [
  healthRoutes,
  identityRoutes,
  mediaRoutes,
  fleetRoutes,
];

/** Every API route. The API asserts at startup that each has exactly one handler. */
export const allRoutes: readonly RouteDef[] = groups.flatMap((g) => Object.values(g));
