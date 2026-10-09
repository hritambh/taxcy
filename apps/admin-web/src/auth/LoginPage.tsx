import { PhoneE164 } from '@taxcy/contracts';
import { Car } from 'lucide-react';
import { useState, type SubmitEvent } from 'react';
import { Button, Field, InlineError, Input } from '../components/ui.js';
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
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-50 px-4">
      <div className="w-full max-w-sm">
        <div className="mb-6 flex items-center gap-2 text-brand-700">
          <Car className="size-6" aria-hidden />
          <span className="text-lg font-semibold">Taxcy</span>
        </div>
        <div className="rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
          <h1 className="text-lg font-semibold text-slate-900">{title}</h1>
          {subtitle && <p className="mt-1 text-sm text-slate-600">{subtitle}</p>}
          <div className="mt-5">{children}</div>
        </div>
      </div>
    </main>
  );
}

export function LoginPage() {
  const auth = useAuth();
  const [phoneInput, setPhoneInput] = useState('');
  const [phone, setPhone] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const [phoneError, setPhoneError] = useState<string | null>(null);

  async function sendCode(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    const candidate = normalizeIndianMobile(phoneInput);
    if (!PhoneE164.safeParse(candidate).success) {
      setPhoneError('Enter a 10-digit Indian mobile number');
      return;
    }
    setPhoneError(null);
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
      <AuthShell
        title="Sign in"
        subtitle="Fleet owners and managers sign in with their mobile number."
      >
        <form onSubmit={(e) => void sendCode(e)} className="space-y-4" noValidate>
          <Field label="Mobile number" error={phoneError}>
            {(props) => (
              <div className="flex">
                <span className="inline-flex items-center rounded-l-md border border-r-0 border-slate-300 bg-slate-50 px-3 text-sm text-slate-600">
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
            Send code
          </Button>
        </form>
      </AuthShell>
    );
  }

  return (
    <AuthShell title="Enter the code" subtitle={`We sent a 6-digit code to ${phone}.`}>
      <form onSubmit={(e) => void verify(e)} className="space-y-4" noValidate>
        <Field
          label="One-time code"
          hint={
            import.meta.env.DEV
              ? 'Local development: the code is printed in the API log (otp.issued … code=…).'
              : undefined
          }
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
          Verify and sign in
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
          Use a different number
        </Button>
      </form>
    </AuthShell>
  );
}
