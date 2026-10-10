import 'i18next';
import type { en } from './locales/en.js';

// Typed keys and interpolation values: `t('nav.trips')` is checked against the English resource.
declare module 'i18next' {
  interface CustomTypeOptions {
    defaultNS: 'translation';
    resources: { translation: typeof en };
  }
}
