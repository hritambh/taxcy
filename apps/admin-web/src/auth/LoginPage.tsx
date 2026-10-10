import { PhoneE164 } from '@taxcy/contracts';
import { Car } from 'lucide-react';
import { useEffect, useState, type SubmitEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { LanguageSwitcher } from '../components/LanguageSwitcher.js';
import { Button, Field, InlineError, Input } from '../components/ui.js';
import { fmtPhone } from '../lib/format.js';
import { normalizeIndianMobile } from '../lib/labels.js';
import { useAuth } from './context.js';

export function AuthShell({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  const { t } = useTranslation();
  useEffect(() => {
    document.title = t('app.documentTitle', { page: title });
  }, [t, title]);
  return (
    <main className="flex min-h-screen items-center justify-center bg-gradient-to-br from-brand-700 via-brand-800 to-brand-950 px-4">
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

export function LoginPage() {
  const { t } = useTranslation();
  const auth = useAuth();
  const [phoneInput, setPhoneInput] = useState('');
  const [phone, setPhone] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const [phoneInvalid, setPhoneInvalid] = useState(false);

  async function sendCode(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    const candidate = normalizeIndianMobile(phoneInput);
    if (!PhoneE164.safeParse(candidate).success) {
      setPhoneInvalid(true);
      return;
    }
    setPhoneInvalid(false);
    setBusy(true);
    setError(null);
    try {
      await auth.requestOtp(candidate);
      setPhone(candidate);
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }

  async function verify(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!phone) return;
    setBusy(true);
    setError(null);
    try {
      await auth.verifyOtp(phone, code);
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }

  if (!phone) {
    return (
      <AuthShell title={t('auth.signIn')} subtitle={t('auth.signInSubtitle')}>
        <form onSubmit={(e) => void sendCode(e)} className="space-y-4" noValidate>
          <Field
            label={t('auth.mobileNumber')}
            error={phoneInvalid ? t('auth.invalidMobile') : null}
          >
            {(props) => (
              <div className="flex">
                <span className="inline-flex items-center rounded-l-md border border-r-0 border-slate-300 bg-brand-50 px-3 text-sm font-medium text-brand-700">
                  +91
                </span>
                <Input
                  {...props}
                  className="rounded-l-none"
                  inputMode="tel"
                  autoComplete="tel-national"
                  placeholder="98123 45678"
                  value={phoneInput}
                  onChange={(e) => {
                    setPhoneInput(e.target.value);
                  }}
                  autoFocus
                />
              </div>
            )}
          </Field>
          <InlineError error={error} />
          <Button type="submit" busy={busy} className="w-full">
            {t('auth.sendCode')}
          </Button>
        </form>
      </AuthShell>
    );
  }

  return (
    <AuthShell
      title={t('auth.enterCode')}
      subtitle={t('auth.codeSent', { phone: fmtPhone(phone) })}
    >
      <form onSubmit={(e) => void verify(e)} className="space-y-4" noValidate>
        <Field
          label={t('auth.oneTimeCode')}
          hint={import.meta.env.DEV ? t('auth.devCodeHint') : undefined}
        >
          {(props) => (
            <Input
              {...props}
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={6}
              placeholder="123456"
              value={code}
              onChange={(e) => {
                setCode(e.target.value.replace(/\D/g, ''));
              }}
              autoFocus
            />
          )}
        </Field>
        <InlineError error={error} />
        <Button type="submit" busy={busy} disabled={code.length !== 6} className="w-full">
          {t('auth.verify')}
        </Button>
        <Button
          variant="ghost"
          className="w-full"
          onClick={() => {
            setPhone(null);
            setCode('');
            setError(null);
          }}
        >
          {t('auth.differentNumber')}
        </Button>
      </form>
    </AuthShell>
  );
}
