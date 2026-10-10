import { AuditSettings as AuditSettingsSchema, PayRule as PayRuleSchema } from '@taxcy/contracts';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../auth/context.js';
import { PayRuleEditor } from '../components/PayRuleEditor.js';
import {
  Button,
  Card,
  Field,
  InlineError,
  Input,
  PageHeader,
  QueryState,
} from '../components/ui.js';
import { api, call } from '../lib/api.js';
import type { AuditSettings, PayRule } from '../lib/api-types.js';
import { keys, useAuditSettings, useDefaultPayRule } from '../lib/queries.js';
import { useApiMutation } from '../lib/mutations.js';

// Labels and hints are under `people.settings.field.<key>` and `<key>Hint`.
const AUDIT_FIELDS: {
  key: Exclude<keyof AuditSettings, 'docAlertDays'>;
  step: number;
}[] = [
  { key: 'fuelKSigma', step: 0.1 },
  { key: 'fuelMinCycles', step: 1 },
  { key: 'fuelPctThreshold', step: 1 },
  { key: 'fuelEwmaAlpha', step: 0.05 },
  { key: 'odoGpsTolerancePct', step: 1 },
];

const isAuditField = (key: unknown): key is keyof AuditSettings =>
  key === 'docAlertDays' || AUDIT_FIELDS.some((f) => f.key === key);

function AuditForm({ initial, editable }: { initial: AuditSettings; editable: boolean }) {
  const { t } = useTranslation();
  const [values, setValues] = useState(initial);
  const [days, setDays] = useState(initial.docAlertDays.join(', '));
  const [problem, setProblem] = useState<string | null>(null);
  const save = useApiMutation(
    (body: AuditSettings) => call(api.PATCH('/settings/audit', { body })),
    [keys.settings, keys.fuel],
  );

  function submit() {
    const parsed = AuditSettingsSchema.safeParse({
      ...values,
      docAlertDays: days
        .split(',')
        .map((d) => d.trim())
        .filter(Boolean)
        .map(Number),
    });
    if (!parsed.success) {
      // Name the fields in the user's language rather than echoing the schema's English.
      const fields = new Set(
        parsed.error.issues.map((i) => {
          const key = i.path[0];
          return isAuditField(key) ? t(`people.settings.field.${key}`) : i.path.join('.');
        }),
      );
      setProblem(t('people.settings.invalidFields', { fields: [...fields].join('; ') }));
      return;
    }
    setProblem(null);
    save.mutate(parsed.data);
  }

  return (
    <div className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        {AUDIT_FIELDS.map((f) => (
          <Field
            key={f.key}
            label={t(`people.settings.field.${f.key}`)}
            hint={t(`people.settings.field.${f.key}Hint`)}
          >
            {(props) => (
              <Input
                {...props}
                type="number"
                step={f.step}
                disabled={!editable}
                value={values[f.key]}
                onChange={(e) => {
                  setValues((v) => ({ ...v, [f.key]: Number(e.target.value) }));
                }}
              />
            )}
          </Field>
        ))}
        <Field
          label={t('people.settings.field.docAlertDays')}
          hint={t('people.settings.field.docAlertDaysHint')}
        >
          {(props) => (
            <Input
              {...props}
              disabled={!editable}
              value={days}
              onChange={(e) => {
                setDays(e.target.value);
              }}
            />
          )}
        </Field>
      </div>
      {problem && <p className="text-sm text-red-600">{problem}</p>}
      <InlineError error={save.error} />
      {save.isSuccess && (
        <p className="text-sm text-emerald-700">{t('people.settings.auditSaved')}</p>
      )}
      {editable && (
        <div className="flex justify-end">
          <Button busy={save.isPending} onClick={submit}>
            {t('people.settings.saveThresholds')}
          </Button>
        </div>
      )}
    </div>
  );
}

function PayForm({ initial, editable }: { initial: PayRule; editable: boolean }) {
  const { t } = useTranslation();
  const [rule, setRule] = useState(initial);
  const [problem, setProblem] = useState<string | null>(null);
  const save = useApiMutation(
    (body: PayRule) => call(api.PUT('/settings/driver-pay', { body })),
    [keys.settings, keys.settlements, keys.drivers],
  );
  return (
    <div className="space-y-4">
      <PayRuleEditor value={rule} onChange={setRule} disabled={!editable} />
      {problem && <p className="text-sm text-red-600">{problem}</p>}
      <InlineError error={save.error} />
      {save.isSuccess && (
        <p className="text-sm text-emerald-700">{t('people.settings.paySaved')}</p>
      )}
      {editable && (
        <div className="flex justify-end">
          <Button
            busy={save.isPending}
            onClick={() => {
              const parsed = PayRuleSchema.safeParse(rule);
              if (!parsed.success) {
                setProblem(t('people.settings.checkPayRule'));
                return;
              }
              setProblem(null);
              save.mutate(rule);
            }}
          >
            {t('people.settings.saveDefaultPay')}
          </Button>
        </div>
      )}
    </div>
  );
}

export function SettingsPage() {
  const { t } = useTranslation();
  const auth = useAuth();
  const audit = useAuditSettings();
  const pay = useDefaultPayRule();
  return (
    <>
      <PageHeader
        title={t('people.settings.title')}
        description={auth.isOwner ? undefined : t('people.settings.ownerOnly')}
      />
      <div className="space-y-4">
        <Card title={t('people.settings.auditTitle')}>
          <QueryState query={audit}>
            {(a) => <AuditForm initial={a} editable={auth.isOwner} />}
          </QueryState>
        </Card>
        <Card title={t('people.settings.payTitle')}>
          <p className="mb-4 text-sm text-slate-600">{t('people.settings.payHelp')}</p>
          <QueryState query={pay}>
            {(p) => <PayForm initial={p} editable={auth.isOwner} />}
          </QueryState>
        </Card>
      </div>
    </>
  );
}
