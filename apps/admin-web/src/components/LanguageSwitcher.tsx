import { cn } from '@taxcy/ui';
import { Languages } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { currentLanguage, isLanguage, LANGUAGES, setLanguage } from '../i18n/index.js';

/** Picks the console language; each option is written in its own language. */
export function LanguageSwitcher({ className }: { className?: string }) {
  const { t } = useTranslation();
  return (
    <label className={cn('flex items-center gap-1.5 text-sm', className)}>
      <Languages className="size-4 shrink-0" aria-hidden />
      <span className="sr-only">{t('common.language')}</span>
      <select
        className="min-w-0 flex-1 cursor-pointer rounded-md border border-white/20 bg-white/10 px-2 py-1 text-sm text-white focus-visible:outline-2 focus-visible:outline-white [&>option]:text-slate-900"
        value={currentLanguage()}
        onChange={(e) => {
          if (isLanguage(e.target.value)) void setLanguage(e.target.value);
        }}
      >
        {Object.entries(LANGUAGES).map(([code, language]) => (
          <option key={code} value={code} lang={code}>
            {language.name}
          </option>
        ))}
      </select>
    </label>
  );
}
