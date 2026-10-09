import { AlertsModule } from './modules/alerts/alerts.module.js';
import { HealthModule } from './modules/health/health.module.js';
import { IdentityModule } from './modules/identity/identity.module.js';
import { MediaModule } from './modules/media/media.module.js';

/** Business modules, shared by the HTTP app and the workers process. */
export const DOMAIN_MODULES = [AlertsModule, HealthModule, IdentityModule, MediaModule];
