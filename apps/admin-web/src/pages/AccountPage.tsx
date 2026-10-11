import { useQueryClient } from '@tanstack/react-query';
import { useState, type SubmitEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { passwordProblem, type PasswordProblem } from '../auth/password-rules.js';
import { NewPasswordFields, PasswordInput } from '../components/PasswordInput.js';
import {
  Badge,
  Button,
  Card,
  Field,
  InlineError,
  PageHeader,
  QueryState,
} from '../components/ui.js';
import { api, callVoid } from '../lib/api.js';
import type { Me } from '../lib/api-types.js';
import { ApiError } from '../lib/errors.js';
import { fmtPhone } from '../lib/format.js';
import { keys, useMe } from '../lib/queries.js';

export interface PasswordChange {
  currentPassword?: string;
  newPassword: string;
}

/** Set a first password, or change it (the current one is asked for once there is one). */
export function PasswordForm({
  hasPassword,
  username,
  onSubmit,
}: {
  hasPassword: boolean;
  /** The phone, so a password manager files the password under it. */
  username: string;
  onSubmit: (change: PasswordChange) => Promise<void>;
}) {
  const { t } = useTranslation();
  const [current, setCurrent] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [problem, setProblem] = useState<PasswordProblem | null>(null);
  const [error, setError] = useState<unknown>(null);
  const [saved, setSaved] = useState<'set' | 'changed' | null>(null);
  const [busy, setBusy] = useState(false);
  const wrongCurrent = error instanceof ApiError && error.code === 'INVALID_CREDENTIALS';

  async function submit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    const found = passwordProblem(password, confirm);
    setProblem(found);
    setSaved(null);
    if (found) return;
    setBusy(true);
    setError(null);
    try {
      await onSubmit(
        hasPassword
          ? { currentPassword: current, newPassword: password }
          : { newPassword: password },
      );
      setSaved(hasPassword ? 'changed' : 'set');
      setCurrent('');
      setPassword('');
      setConfirm('');
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={(e) => void submit(e)} className="max-w-sm space-y-4" noValidate>
      <p className="text-sm text-slate-600">
        {hasPassword ? t('account.hasPassword') : t('account.noPassword')}
      </p>
      <input type="text" name="username" autoComplete="username" value={username} readOnly hidden />
      {hasPassword && (
        <Field
          label={t('account.currentPassword')}
          error={wrongCurrent ? t('account.currentWrong') : null}
        >
          {(props) => (
            <PasswordInput
              {...props}
              autoComplete="current-password"
              value={current}
              onChange={(e) => {
                setCurrent(e.target.value);
              }}
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
      />
      {!wrongCurrent && <InlineError error={error} />}
      {saved && (
        <p className="text-sm text-emerald-700" role="status">
          {saved === 'changed' ? t('account.changed') : t('account.set')}
        </p>
      )}
      <Button type="submit" busy={busy} disabled={hasPassword && current === ''}>
        {hasPassword ? t('account.changePassword') : t('account.setPassword')}
      </Button>
    </form>
  );
}

function Profile({ me }: { me: Me }) {
  const { t } = useTranslation();
  const notSet = <span className="text-slate-400">{t('account.notSet')}</span>;
  return (
    <dl className="grid gap-x-6 gap-y-3 text-sm sm:grid-cols-[max-content_1fr]">
      <dt className="font-medium text-slate-500">{t('account.name')}</dt>
      <dd className="text-slate-900">{me.user.name ?? notSet}</dd>
      <dt className="font-medium text-slate-500">{t('account.mobile')}</dt>
      <dd className="text-slate-900">{fmtPhone(me.user.phone)}</dd>
      <dt className="font-medium text-slate-500">{t('account.google')}</dt>
      <dd className="space-y-1">
        {me.user.googleLinked ? (
          <Badge tone="success">{t('account.googleLinked')}</Badge>
        ) : (
          <>
            <Badge tone="neutral">{t('account.googleNotLinked')}</Badge>
            <p className="text-xs text-slate-500">{t('account.googleNotLinkedHelp')}</p>
          </>
        )}
      </dd>
      <dt className="font-medium text-slate-500">{t('account.email')}</dt>
      <dd className="text-slate-900">{me.user.email ?? notSet}</dd>
    </dl>
  );
}

/** The signed-in person's own account: profile, Google link and password. */
export function AccountPage() {
  const { t } = useTranslation();
  const me = useMe();
  const queryClient = useQueryClient();
  return (
    <>
      <PageHeader title={t('account.title')} description={t('account.description')} />
      <QueryState query={me}>
        {(data) => (
          <div className="space-y-4">
            <Card title={t('account.profile')}>
              <Profile me={data} />
            </Card>
            <Card title={t('account.passwordTitle')}>
              <PasswordForm
                hasPassword={data.user.hasPassword}
                username={data.user.phone}
                onSubmit={async (body) => {
                  await callVoid(api.POST('/me/password', { body }));
                  await queryClient.invalidateQueries({ queryKey: keys.me });
                }}
              />
            </Card>
          </div>
        )}
      </QueryState>
    </>
  );
}
