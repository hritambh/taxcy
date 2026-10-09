import { AlertsModule } from './modules/alerts/alerts.module.js';
import { FleetModule } from './modules/fleet/fleet.module.js';
import { FuelModule } from './modules/fuel/fuel.module.js';
import { HealthModule } from './modules/health/health.module.js';
import { IdentityModule } from './modules/identity/identity.module.js';
import { MediaModule } from './modules/media/media.module.js';
import { TripsModule } from './modules/trips/trips.module.js';

/** Business modules, shared by the HTTP app and the workers process. */
export const DOMAIN_MODULES = [
  AlertsModule,
  HealthModule,
  IdentityModule,
  MediaModule,
  FleetModule,
  TripsModule,
  FuelModule,
];
