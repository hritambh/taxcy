import { useState, type SubmitEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, Field, InlineError, Input } from '../components/ui.js';
import { cn } from '@taxcy/ui';
import { AuthShell } from './LoginPage.js';
import { useAuth } from './context.js';

/** First sign-in with no organization yet: create a fleet or register as an owner-driver. */
export function CreateOrgPage() {
  const { t } = useTranslation();
  const auth = useAuth();
  const [name, setName] = useState('');
  const [kind, setKind] = useState<'fleet' | 'dco'>('fleet');
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await auth.createOrg(name.trim(), kind);
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthShell title={t('auth.setUpBusiness')} subtitle={t('auth.notInFleet')}>
      <form onSubmit={(e) => void submit(e)} className="space-y-4">
        <fieldset className="space-y-2">
          <legend className="text-sm font-medium text-slate-700">{t('auth.iAm')}</legend>
          {(
            [
              ['fleet', t('auth.fleetOwner'), t('auth.fleetOwnerHelp')],
              ['dco', t('auth.ownerDriver'), t('auth.ownerDriverHelp')],
            ] as const
          ).map(([value, label, help]) => (
            <label
              key={value}
              className={cn(
                'flex cursor-pointer gap-3 rounded-md border p-3 text-sm',
                kind === value ? 'border-brand-500 bg-brand-50' : 'border-slate-200',
              )}
            >
              <input
                type="radio"
                name="kind"
                value={value}
                checked={kind === value}
                onChange={() => {
                  setKind(value);
                }}
                className="mt-0.5"
              />
              <span>
                <span className="block font-medium text-slate-900">{label}</span>
                <span className="text-slate-600">{help}</span>
              </span>
            </label>
          ))}
        </fieldset>
        <Field label={t('auth.businessName')}>
          {(props) => (
            <Input
              {...props}
              required
              minLength={2}
              placeholder={t('auth.businessNamePlaceholder')}
              value={name}
              onChange={(e) => {
                setName(e.target.value);
              }}
            />
          )}
        </Field>
        <InlineError error={error} />
        <Button type="submit" busy={busy} disabled={name.trim().length < 2} className="w-full">
          {t('auth.create')}
        </Button>
        <Button variant="ghost" className="w-full" onClick={() => void auth.logout()}>
          {t('nav.signOut')}
        </Button>
      </form>
    </AuthShell>
  );
}

/** Signed in with only a driver role in the active org: the console isn't for them. */
export function NotStaffPage() {
  const { t } = useTranslation();
  const auth = useAuth();
  const staffOrgs =
    auth.session?.memberships.filter(
      (m) => m.roles.includes('owner') || m.roles.includes('manager'),
    ) ?? [];
  return (
    <AuthShell
      title={t('auth.staffOnly')}
      subtitle={t('auth.driverHere', {
        org: auth.activeMembership?.orgName ?? t('auth.thisOrganization'),
      })}
    >
      <div className="space-y-2">
        {staffOrgs.map((m) => (
          <Button
            key={m.orgId}
            variant="secondary"
            className="w-full"
            onClick={() => void auth.switchOrg(m.orgId)}
          >
            {t('auth.switchTo', { org: m.orgName })}
          </Button>
        ))}
        <Button variant="ghost" className="w-full" onClick={() => void auth.logout()}>
          {t('nav.signOut')}
        </Button>
      </div>
    </AuthShell>
  );
}
