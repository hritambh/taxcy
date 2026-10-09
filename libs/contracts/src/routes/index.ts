import type { RouteDef } from '../http.js';
import { healthRoutes } from './health.js';
import { identityRoutes } from './identity.js';

export { healthRoutes } from './health.js';
export * from './identity.js';

/** Every API route. The API asserts at startup that each has exactly one handler. */
export const allRoutes: readonly RouteDef[] = [
  ...Object.values(healthRoutes),
  ...Object.values(identityRoutes),
];
