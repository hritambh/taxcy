import type { RouteDef } from '../http.js';
import { healthRoutes } from './health.js';

export { healthRoutes } from './health.js';

/** Every API route. The API asserts at startup that each has exactly one handler. */
export const allRoutes: readonly RouteDef[] = [...Object.values(healthRoutes)];
