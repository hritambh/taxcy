import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach, beforeEach } from 'vitest';
import { i18n } from '../i18n/index.js';

// Tests read in English unless they switch language themselves.
beforeEach(async () => {
  await i18n.changeLanguage('en');
});

afterEach(() => {
  cleanup();
  window.localStorage.clear();
});
