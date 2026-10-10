import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { safeLocalStorage } from '../lib/storage.js';
import { en } from './locales/en.js';
import { hi } from './locales/hi.js';

/**
 * The languages the console offers. To add one: write `locales/<code>.ts` typed as
 * `Translation` and list it here with its own name and Intl locale.
 */
export const LANGUAGES = {
  en: { name: 'English', intl: 'en-IN', resources: en },
  hi: { name: 'हिन्दी', intl: 'hi-IN', resources: hi },
} as const;

export type Language = keyof typeof LANGUAGES;

const STORAGE_KEY = 'taxcy.language';

export const isLanguage = (value: unknown): value is Language =>
  typeof value === 'string' && Object.hasOwn(LANGUAGES, value);

/** The saved choice, else the first browser language we support, else English. */
export function detectLanguage(
  stored: string | null,
  browserLanguages: readonly string[] = typeof navigator === 'undefined' ? [] : navigator.languages,
): Language {
  if (isLanguage(stored)) return stored;
  for (const tag of browserLanguages) {
    const base = tag.toLowerCase().split('-')[0];
    if (isLanguage(base)) return base;
  }
  return 'en';
}

export const currentLanguage = (): Language =>
  isLanguage(i18n.resolvedLanguage) ? i18n.resolvedLanguage : 'en';

/** The Intl locale for numbers, money and dates in the current language. */
export const intlLocale = (): string => LANGUAGES[currentLanguage()].intl;

/** Switches language and remembers the choice in this browser. */
export async function setLanguage(language: Language): Promise<void> {
  safeLocalStorage.set(STORAGE_KEY, language);
  await i18n.changeLanguage(language);
}

i18n.on('languageChanged', (language) => {
  if (typeof document !== 'undefined') document.documentElement.lang = language;
});

void i18n.use(initReactI18next).init({
  resources: Object.fromEntries(
    Object.entries(LANGUAGES).map(([code, l]) => [code, { translation: l.resources }]),
  ),
  lng: detectLanguage(safeLocalStorage.get(STORAGE_KEY)),
  fallbackLng: 'en',
  supportedLngs: Object.keys(LANGUAGES),
  // React escapes rendered text already.
  interpolation: { escapeValue: false },
  initAsync: false,
});

export { i18n };
