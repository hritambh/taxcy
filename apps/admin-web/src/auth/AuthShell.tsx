import { cn } from '@taxcy/ui';
import { Car } from 'lucide-react';
import { useEffect, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { LanguageSwitcher } from '../components/LanguageSwitcher.js';

/** The blue sign-in backdrop with the logo, language switcher and a white card. */
export function AuthShell({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: ReactNode;
  children: ReactNode;
}) {
  const { t } = useTranslation();
  useEffect(() => {
    document.title = t('app.documentTitle', { page: title });
  }, [t, title]);
  return (
    <main className="flex min-h-screen items-center justify-center bg-gradient-to-br from-brand-700 via-brand-800 to-brand-950 px-4 py-8">
      <div className="w-full max-w-sm">
        <div className="mb-6 flex items-center gap-2.5 text-white">
          <span className="flex size-10 items-center justify-center rounded-xl bg-white text-brand-700 shadow-md">
            <Car className="size-5" aria-hidden />
          </span>
          <span className="text-2xl font-semibold tracking-tight">{t('app.name')}</span>
          <LanguageSwitcher className="ml-auto text-brand-100" />
        </div>
        <div className="rounded-2xl bg-white p-6 shadow-2xl shadow-brand-950/30">
          <h1 className="text-lg font-semibold text-brand-950">{title}</h1>
          {subtitle && <p className="mt-1 text-sm text-slate-600">{subtitle}</p>}
          <div className="mt-5">{children}</div>
        </div>
      </div>
    </main>
  );
}

/** A text-style button for switching between sign-in screens. */
export function LinkButton({
  onClick,
  children,
  className,
}: {
  onClick: () => void;
  children: ReactNode;
  className?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'rounded-sm font-medium text-brand-700 hover:text-brand-900 hover:underline focus-visible:outline-2 focus-visible:outline-brand-500',
        className,
      )}
    >
      {children}
    </button>
  );
}

/** A horizontal rule with a word in the middle ("or"). */
export function Divider({ label }: { label: string }) {
  return (
    <div className="my-4 flex items-center gap-3 text-xs text-slate-500" role="separator">
      <span className="h-px flex-1 bg-slate-200" />
      {label}
      <span className="h-px flex-1 bg-slate-200" />
    </div>
  );
}
