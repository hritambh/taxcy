import { useState, type ReactNode, type SubmitEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { NewPasswordFields } from '../components/PasswordInput.js';
import { Button, Field, InlineError, Input } from '../components/ui.js';
import { ApiError } from '../lib/errors.js';
import { fmtPhone } from '../lib/format.js';
import { AuthShell, LinkButton } from './AuthShell.js';
import { useAuth } from './context.js';
import type { PhoneRequired } from './GoogleSignIn.js';
import { passwordProblem, type PasswordProblem } from './password-rules.js';
import { PhoneCodeSteps, type CodeSent } from './PhoneCodeSteps.js';

interface PhoneState {
  phoneInput: string;
  onPhoneInput: (value: string) => void;
}

type Step =
  | { step: 'verify'; attempt: number; start?: CodeSent & { error: unknown } }
  | { step: 'password'; code: string; sent: CodeSent };

const isCodeError = (e: unknown) =>
  e instanceof ApiError && (e.code === 'OTP_INVALID' || e.code === 'OTP_EXPIRED');

/**
 * Sign up, or reset a forgotten password: phone → SMS code → password. The API checks
 * the code together with the password, so a wrong code sends the user back to that step.
 */
export function PasswordSetupPage({
  phoneInput,
  onPhoneInput,
  purpose,
  onSignIn,
  onReset,
  google,
}: PhoneState & {
  purpose: 'signup' | 'reset';
  onSignIn: () => void;
  onReset: () => void;
  /** The Google option, shown under the phone step when signing up. */
  google: ReactNode;
}) {
  const { t } = useTranslation();
  const auth = useAuth();
  const [step, setStep] = useState<Step>({ step: 'verify', attempt: 0 });
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [problem, setProblem] = useState<PasswordProblem | null>(null);
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const signup = purpose === 'signup';

  if (step.step === 'verify') {
    return (
      <PhoneCodeSteps
        key={step.attempt}
        phoneInput={phoneInput}
        onPhoneInput={onPhoneInput}
        {...(step.start ? { start: step.start } : {})}
        title={signup ? t('auth.signUpTitle') : t('auth.resetTitle')}
        subtitle={signup ? t('auth.signUpSubtitle') : t('auth.resetSubtitle')}
        submitLabel={t('auth.continue')}
        onCode={(_phone, code, sent) => {
          setStep({ step: 'password', code, sent });
          return Promise.resolve();
        }}
        footer={
          <>
            {google}
            <div className="mt-5 text-center text-sm text-slate-600">
              {signup ? (
                <>
                  {t('auth.haveAccount')}{' '}
                  <LinkButton onClick={onSignIn}>{t('auth.signInButton')}</LinkButton>
                </>
              ) : (
                <LinkButton onClick={onSignIn}>{t('auth.backToSignIn')}</LinkButton>
              )}
            </div>
          </>
        }
      />
    );
  }

  const { code, sent } = step;

  async function submit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    const found = passwordProblem(password, confirm);
    setProblem(found);
    if (found) return;
    setBusy(true);
    setError(null);
    try {
      const trimmed = name.trim();
      if (signup)
        await auth.signup({
          phone: sent.phone,
          code,
          password,
          ...(trimmed ? { name: trimmed } : {}),
        });
      else await auth.resetPassword({ phone: sent.phone, code, password });
    } catch (e) {
      if (isCodeError(e))
        setStep({ step: 'verify', attempt: Date.now(), start: { ...sent, error: e } });
      else setError(e);
    } finally {
      setBusy(false);
    }
  }

  const accountExists = error instanceof ApiError && error.code === 'ACCOUNT_EXISTS';

  return (
    <AuthShell
      title={signup ? t('auth.choosePassword') : t('auth.newPasswordTitle')}
      subtitle={t(signup ? 'auth.choosePasswordSubtitle' : 'auth.newPasswordSubtitle', {
        phone: fmtPhone(sent.phone),
      })}
    >
      <form onSubmit={(e) => void submit(e)} className="space-y-4" noValidate>
        {/* Lets password managers save the new password against the number. */}
        <input
          type="text"
          name="username"
          autoComplete="username"
          value={sent.phone}
          readOnly
          hidden
        />
        {signup && (
          <Field label={t('auth.yourName')}>
            {(props) => (
              <Input
                {...props}
                autoComplete="name"
                maxLength={100}
                placeholder={t('auth.namePlaceholder')}
                value={name}
                onChange={(e) => {
                  setName(e.target.value);
                }}
                autoFocus
              />
            )}
          </Field>
        )}
        <NewPasswordFields
          password={password}
          confirm={confirm}
          onPassword={setPassword}
          onConfirm={setConfirm}
          problem={problem}
          passwordLabel={signup ? t('auth.password') : t('auth.newPassword')}
          autoFocus={!signup}
        />
        <InlineError error={error} />
        {accountExists && (
          <div className="flex gap-2">
            <Button variant="secondary" className="flex-1" onClick={onSignIn}>
              {t('auth.signInButton')}
            </Button>
            <Button variant="secondary" className="flex-1" onClick={onReset}>
              {t('auth.resetPassword')}
            </Button>
          </div>
        )}
        <Button type="submit" busy={busy} disabled={accountExists} className="w-full">
          {signup ? t('auth.createAccount') : t('auth.saveAndSignIn')}
        </Button>
        <div className="text-center text-sm">
          <LinkButton
            onClick={() => {
              setError(null);
              setStep({ step: 'verify', attempt: Date.now() });
            }}
          >
            {t('auth.differentNumber')}
          </LinkButton>
        </div>
      </form>
    </AuthShell>
  );
}

/**
 * First Google sign-in: tie the Google account to a mobile number (fleets and invites
 * go by phone). An expired link token or a clash sends the user back to start over.
 */
export function GoogleLinkPage({
  phoneInput,
  onPhoneInput,
  pending,
  onRestart,
  onCancel,
}: PhoneState & {
  pending: PhoneRequired;
  onRestart: (reason: unknown) => void;
  onCancel: () => void;
}) {
  const { t } = useTranslation();
  const auth = useAuth();
  const account = [pending.name, pending.email].filter(Boolean).join(' · ');

  return (
    <PhoneCodeSteps
      phoneInput={phoneInput}
      onPhoneInput={onPhoneInput}
      title={t('auth.google.verifyTitle')}
      subtitle={t('auth.google.verifySubtitle')}
      submitLabel={t('auth.verify')}
      intro={
        account ? (
          <p className="mb-4 rounded-md bg-brand-50 px-3 py-2 text-sm text-brand-900">
            {t('auth.google.signedInAs', { account })}
          </p>
        ) : null
      }
      onCode={async (phone, code) => {
        try {
          await auth.googleLink({ linkToken: pending.linkToken, phone, code });
        } catch (e) {
          if (e instanceof ApiError && e.code === 'GOOGLE_TOKEN_INVALID')
            onRestart(new Error(t('auth.google.expired')));
          else if (e instanceof ApiError && e.code === 'GOOGLE_ACCOUNT_CONFLICT') onRestart(e);
          else throw e;
        }
      }}
      footer={
        <div className="mt-5 text-center text-sm">
          <LinkButton onClick={onCancel}>{t('auth.backToSignIn')}</LinkButton>
        </div>
      }
    />
  );
}
