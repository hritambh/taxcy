import { useQuery } from '@tanstack/react-query';
import { useState, type ReactNode, type SubmitEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { PasswordInput } from '../components/PasswordInput.js';
import { Button, Field, InlineError } from '../components/ui.js';
import { ApiError } from '../lib/errors.js';
import { parseIndianMobile } from '../lib/labels.js';
import { AuthShell, Divider, LinkButton } from './AuthShell.js';
import { useAuth } from './context.js';
import { GoogleSignIn, type PhoneRequired } from './GoogleSignIn.js';
import { GoogleLinkPage, PasswordSetupPage } from './SignUpPages.js';
import { PhoneCodeSteps, PhoneInput } from './PhoneCodeSteps.js';

type Screen = 'password' | 'sms' | 'signup' | 'reset';
type View = { name: Screen } | { name: 'google'; pending: PhoneRequired };

/**
 * Signed out: phone + password by default, with an SMS code, sign-up, a forgotten
 * password and Google as the other ways in. The number typed carries across screens.
 */
export function LoginPage() {
  const { t } = useTranslation();
  const auth = useAuth();
  const [view, setView] = useState<View>({ name: 'password' });
  const [phoneInput, setPhoneInput] = useState('');
  // An error to show on the sign-in screen after being sent back to it.
  const [notice, setNotice] = useState<unknown>(null);
  const config = useQuery({
    queryKey: ['auth-config'],
    queryFn: () => auth.loadAuthConfig(),
    staleTime: 300_000,
    retry: 1,
  });

  const go = (name: Screen) => () => {
    setNotice(null);
    setView({ name });
  };
  const onPhoneRequired = (pending: PhoneRequired) => {
    setNotice(null);
    setView({ name: 'google', pending });
  };
  const google = (context: 'signin' | 'signup') =>
    config.data && config.data.google.mode !== 'off' ? (
      <>
        <Divider label={t('auth.or')} />
        <GoogleSignIn
          config={config.data.google}
          context={context}
          onPhoneRequired={onPhoneRequired}
        />
      </>
    ) : null;
  const phone = { phoneInput, onPhoneInput: setPhoneInput };

  switch (view.name) {
    case 'password':
      return (
        <PasswordSignIn
          {...phone}
          notice={notice}
          onForgot={go('reset')}
          footer={
            <>
              {google('signin')}
              <Links>
                <LinkButton onClick={go('sms')}>{t('auth.useSmsCode')}</LinkButton>
                <span>
                  {t('auth.noAccount')}{' '}
                  <LinkButton onClick={go('signup')}>{t('auth.signUp')}</LinkButton>
                </span>
              </Links>
            </>
          }
        />
      );
    case 'sms':
      return (
        <PhoneCodeSteps
          {...phone}
          title={t('auth.signIn')}
          subtitle={t('auth.smsSubtitle')}
          submitLabel={t('auth.verify')}
          onCode={(p, code) => auth.verifyOtp(p, code)}
          footer={
            <Links>
              <LinkButton onClick={go('password')}>{t('auth.usePassword')}</LinkButton>
            </Links>
          }
        />
      );
    case 'signup':
    case 'reset':
      return (
        <PasswordSetupPage
          key={view.name}
          {...phone}
          purpose={view.name}
          onSignIn={go('password')}
          onReset={go('reset')}
          google={view.name === 'signup' ? google('signup') : null}
        />
      );
    case 'google':
      return (
        <GoogleLinkPage
          {...phone}
          pending={view.pending}
          onRestart={(error) => {
            setView({ name: 'password' });
            setNotice(error);
          }}
          onCancel={go('password')}
        />
      );
  }
}

function Links({ children }: { children: ReactNode }) {
  return (
    <div className="mt-5 flex flex-col items-center gap-2 text-sm text-slate-600">{children}</div>
  );
}

function PasswordSignIn({
  phoneInput,
  onPhoneInput,
  notice,
  onForgot,
  footer,
}: {
  phoneInput: string;
  onPhoneInput: (value: string) => void;
  notice: unknown;
  onForgot: () => void;
  footer: ReactNode;
}) {
  const { t } = useTranslation();
  const auth = useAuth();
  const [password, setPassword] = useState('');
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const [phoneInvalid, setPhoneInvalid] = useState(false);

  async function submit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    const phone = parseIndianMobile(phoneInput);
    setPhoneInvalid(!phone);
    if (!phone) return;
    setBusy(true);
    setError(null);
    try {
      await auth.passwordLogin(phone, password);
    } catch (e) {
      setError(e);
      if (e instanceof ApiError && e.code === 'INVALID_CREDENTIALS') setPassword('');
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthShell title={t('auth.signIn')} subtitle={t('auth.signInSubtitle')}>
      <form onSubmit={(e) => void submit(e)} className="space-y-4" noValidate>
        <InlineError error={notice} />
        <Field label={t('auth.mobileNumber')} error={phoneInvalid ? t('auth.invalidMobile') : null}>
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
        <Field label={t('auth.password')}>
          {(props) => (
            <PasswordInput
              {...props}
              autoComplete="current-password"
              value={password}
              onChange={(e) => {
                setPassword(e.target.value);
              }}
            />
          )}
        </Field>
        <div className="-mt-2 flex justify-end text-sm">
          <LinkButton onClick={onForgot}>{t('auth.forgotPassword')}</LinkButton>
        </div>
        <InlineError error={error} />
        <Button type="submit" busy={busy} disabled={password === ''} className="w-full">
          {t('auth.signInButton')}
        </Button>
      </form>
      {footer}
    </AuthShell>
  );
}
