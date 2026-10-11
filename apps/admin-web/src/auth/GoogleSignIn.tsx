import { FlaskConical } from 'lucide-react';
import { useEffect, useRef, useState, type SubmitEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, Field, InlineError, Input } from '../components/ui.js';
import { currentLanguage } from '../i18n/index.js';
import type { AuthConfig } from '../lib/api-types.js';
import { useAuth, type GoogleOutcome } from './context.js';
import { loadGoogleIdentity } from './google-identity.js';

export type PhoneRequired = Extract<GoogleOutcome, { status: 'phone_required' }>;

interface GoogleProps {
  config: AuthConfig['google'];
  /** Words the button for the screen it's on. */
  context: 'signin' | 'signup';
  /** A first Google sign-in: the account still has to be tied to a phone. */
  onPhoneRequired: (pending: PhoneRequired) => void;
}

/**
 * "Continue with Google": Google's own button when the API has a web client id, a
 * clearly-marked local stand-in in development, and nothing when Google is off.
 */
export function GoogleSignIn({ config, context, onPhoneRequired }: GoogleProps) {
  if (config.mode === 'google' && config.webClientId)
    return (
      <RealGoogleButton
        clientId={config.webClientId}
        context={context}
        onPhoneRequired={onPhoneRequired}
      />
    );
  if (config.mode === 'dev') return <DevGoogleButton onPhoneRequired={onPhoneRequired} />;
  return null;
}

function RealGoogleButton({
  clientId,
  context,
  onPhoneRequired,
}: {
  clientId: string;
  context: GoogleProps['context'];
  onPhoneRequired: GoogleProps['onPhoneRequired'];
}) {
  const { t } = useTranslation();
  const auth = useAuth();
  const container = useRef<HTMLDivElement>(null);
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const [loadFailed, setLoadFailed] = useState(false);
  const language = currentLanguage();

  // Google calls back long after render; keep it pointed at the current props.
  const onCredential = useRef<(idToken: string) => Promise<void>>(() => Promise.resolve());
  useEffect(() => {
    onCredential.current = async (idToken) => {
      setBusy(true);
      setError(null);
      try {
        const outcome = await auth.googleSignIn(idToken);
        if (outcome.status === 'phone_required') onPhoneRequired(outcome);
      } catch (e) {
        setError(e);
      } finally {
        setBusy(false);
      }
    };
  }, [auth, onPhoneRequired]);

  useEffect(() => {
    let cancelled = false;
    loadGoogleIdentity().then(
      (id) => {
        const parent = container.current;
        if (cancelled || !parent) return;
        id.initialize({
          client_id: clientId,
          callback: ({ credential }) => void onCredential.current(credential),
          ux_mode: 'popup',
          context,
          itp_support: true,
        });
        parent.replaceChildren();
        id.renderButton(parent, {
          type: 'standard',
          theme: 'outline',
          size: 'large',
          shape: 'rectangular',
          text: context === 'signup' ? 'signup_with' : 'continue_with',
          logo_alignment: 'center',
          width: Math.min(400, Math.max(200, parent.offsetWidth || 320)),
          locale: language,
        });
      },
      () => {
        if (!cancelled) setLoadFailed(true);
      },
    );
    return () => {
      cancelled = true;
    };
  }, [clientId, context, language]);

  return (
    <div className="space-y-2">
      {loadFailed ? (
        <p className="text-sm text-slate-600" role="alert">
          {t('auth.google.loadFailed')}
        </p>
      ) : (
        <div
          ref={container}
          className="flex min-h-10 justify-center"
          aria-busy={busy || undefined}
          data-testid="google-button"
        />
      )}
      <InlineError error={error} />
    </div>
  );
}

/** Development only: the API accepts "dev-google:<email>" in place of a Google ID token. */
function DevGoogleButton({ onPhoneRequired }: { onPhoneRequired: GoogleProps['onPhoneRequired'] }) {
  const { t } = useTranslation();
  const auth = useAuth();
  const [open, setOpen] = useState(false);
  const [email, setEmail] = useState('');
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const outcome = await auth.googleSignIn(`dev-google:${email.trim()}`);
      if (outcome.status === 'phone_required') onPhoneRequired(outcome);
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }

  if (!open)
    return (
      <Button
        variant="secondary"
        className="w-full border-dashed border-amber-400 text-amber-800 hover:border-amber-500 hover:bg-amber-50"
        onClick={() => {
          setOpen(true);
        }}
      >
        <FlaskConical className="size-4" aria-hidden />
        {t('auth.google.devButton')}
      </Button>
    );

  return (
    <form
      onSubmit={(e) => void submit(e)}
      className="space-y-3 rounded-md border border-dashed border-amber-400 bg-amber-50/60 p-3"
    >
      <p className="flex items-center gap-1.5 text-sm font-medium text-amber-900">
        <FlaskConical className="size-4" aria-hidden />
        {t('auth.google.devButton')}
      </p>
      <Field label={t('auth.google.devEmail')} hint={t('auth.google.devHint')}>
        {(props) => (
          <Input
            {...props}
            type="email"
            autoComplete="email"
            required
            placeholder="owner@example.com"
            value={email}
            onChange={(e) => {
              setEmail(e.target.value);
            }}
            autoFocus
          />
        )}
      </Field>
      <InlineError error={error} />
      <div className="flex gap-2">
        <Button type="submit" busy={busy} disabled={!/^\S+@\S+\.\S+$/.test(email.trim())}>
          {t('auth.continue')}
        </Button>
        <Button
          variant="ghost"
          onClick={() => {
            setOpen(false);
            setError(null);
          }}
        >
          {t('common.cancel')}
        </Button>
      </div>
    </form>
  );
}
