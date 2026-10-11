import { useState, type InputHTMLAttributes, type ReactNode, type SubmitEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, Field, InlineError, Input } from '../components/ui.js';
import { fmtPhone } from '../lib/format.js';
import { parseIndianMobile } from '../lib/labels.js';
import { AuthShell, LinkButton } from './AuthShell.js';
import { useAuth } from './context.js';
import { useSecondsLeft } from './use-seconds-left.js';

/** A 10-digit Indian mobile, with the +91 shown in front. */
export function PhoneInput(props: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <div className="flex">
      <span className="inline-flex items-center rounded-l-md border border-r-0 border-slate-300 bg-brand-50 px-3 text-sm font-medium text-brand-700">
        +91
      </span>
      <Input
        {...props}
        type="tel"
        className="rounded-l-none"
        inputMode="tel"
        autoComplete="tel-national"
        placeholder="98123 45678"
      />
    </div>
  );
}

/** A code was sent to `phone`; another can be asked for at `resendAt` (a Date.now() time). */
export interface CodeSent {
  phone: string;
  resendAt: number;
}

/**
 * Phone number → SMS code. `onCode` gets the 6 digits; whatever it throws is shown
 * on the code step, so a mistyped code can simply be typed again. Start at the code
 * step by passing `start` (e.g. when a later step reports the code was wrong).
 */
export function PhoneCodeSteps({
  title,
  subtitle,
  phoneInput,
  onPhoneInput,
  start,
  submitLabel,
  onCode,
  intro,
  footer,
}: {
  title: string;
  subtitle: ReactNode;
  phoneInput: string;
  onPhoneInput: (value: string) => void;
  start?: CodeSent & { error?: unknown };
  /** The code step's button. */
  submitLabel: string;
  onCode: (phone: string, code: string, sent: CodeSent) => Promise<void>;
  /** Shown above the form on both steps. */
  intro?: ReactNode;
  /** Shown below the form on the phone step (links to other ways in). */
  footer?: ReactNode;
}) {
  const { t } = useTranslation();
  const auth = useAuth();
  const [sent, setSent] = useState<CodeSent | null>(
    start ? { phone: start.phone, resendAt: start.resendAt } : null,
  );
  const [code, setCode] = useState('');
  const [error, setError] = useState<unknown>(start?.error ?? null);
  const [resent, setResent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [phoneInvalid, setPhoneInvalid] = useState(false);

  async function request(phone: string): Promise<boolean> {
    setBusy(true);
    setError(null);
    try {
      const { resendAfterSeconds } = await auth.requestOtp(phone);
      setSent({ phone, resendAt: Date.now() + resendAfterSeconds * 1000 });
      return true;
    } catch (e) {
      setError(e);
      return false;
    } finally {
      setBusy(false);
    }
  }

  async function sendCode(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    const phone = parseIndianMobile(phoneInput);
    setPhoneInvalid(!phone);
    if (phone) await request(phone);
  }

  async function verify(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!sent) return;
    setBusy(true);
    setError(null);
    setResent(false);
    try {
      await onCode(sent.phone, code, sent);
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }

  if (!sent) {
    return (
      <AuthShell title={title} subtitle={subtitle}>
        {intro}
        <form onSubmit={(e) => void sendCode(e)} className="space-y-4" noValidate>
          <Field
            label={t('auth.mobileNumber')}
            error={phoneInvalid ? t('auth.invalidMobile') : null}
          >
            {(props) => (
              <PhoneInput
                {...props}
                value={phoneInput}
                onChange={(e) => {
                  onPhoneInput(e.target.value);
                }}
                autoFocus
              />
            )}
          </Field>
          <InlineError error={error} />
          <Button type="submit" busy={busy} className="w-full">
            {t('auth.sendCode')}
          </Button>
        </form>
        {footer}
      </AuthShell>
    );
  }

  return (
    <AuthShell
      title={t('auth.enterCode')}
      subtitle={t('auth.codeSent', { phone: fmtPhone(sent.phone) })}
    >
      {intro}
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
        {resent && (
          <p className="text-sm text-emerald-700" role="status">
            {t('auth.codeResent')}
          </p>
        )}
        <Button type="submit" busy={busy} disabled={code.length !== 6} className="w-full">
          {submitLabel}
        </Button>
        <div className="flex flex-wrap items-center justify-between gap-2 text-sm">
          <ResendButton
            resendAt={sent.resendAt}
            disabled={busy}
            onResend={async () => {
              setCode('');
              setResent(await request(sent.phone));
            }}
          />
          <LinkButton
            onClick={() => {
              setSent(null);
              setCode('');
              setError(null);
              setResent(false);
            }}
          >
            {t('auth.differentNumber')}
          </LinkButton>
        </div>
      </form>
    </AuthShell>
  );
}

function ResendButton({
  resendAt,
  disabled,
  onResend,
}: {
  resendAt: number;
  disabled: boolean;
  onResend: () => Promise<void>;
}) {
  const { t } = useTranslation();
  const seconds = useSecondsLeft(resendAt);
  if (seconds > 0) return <span className="text-slate-500">{t('auth.resendIn', { seconds })}</span>;
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={() => void onResend()}
      className="rounded-sm font-medium text-brand-700 hover:text-brand-900 hover:underline focus-visible:outline-2 focus-visible:outline-brand-500 disabled:text-slate-400"
    >
      {t('auth.resendCode')}
    </button>
  );
}
