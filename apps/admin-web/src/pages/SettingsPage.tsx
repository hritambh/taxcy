import { AuditSettings as AuditSettingsSchema, PayRule as PayRuleSchema } from '@taxcy/contracts';
import { useState } from 'react';
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

const AUDIT_FIELDS: {
  key: Exclude<keyof AuditSettings, 'docAlertDays'>;
  label: string;
  hint: string;
  step: number;
}[] = [
  {
    key: 'fuelKSigma',
    label: 'Fuel alert sensitivity (k σ)',
    hint: 'Flag a cycle this many standard deviations worse than usual. Lower = more alerts.',
    step: 0.1,
  },
  {
    key: 'fuelMinCycles',
    label: 'Cycles before using σ',
    hint: 'New vehicles use the percent rule until they have this many normal cycles.',
    step: 1,
  },
  {
    key: 'fuelPctThreshold',
    label: 'New-vehicle threshold (%)',
    hint: 'For new vehicles, flag a cycle this much worse than the usual figure.',
    step: 1,
  },
  {
    key: 'fuelEwmaAlpha',
    label: 'Baseline responsiveness (α)',
    hint: 'How quickly the usual figure follows recent cycles (0.05–0.9).',
    step: 0.05,
  },
  {
    key: 'odoGpsTolerancePct',
    label: 'Odometer vs GPS tolerance (%)',
    hint: 'Flag trips whose odometer distance exceeds the GPS route by more than this.',
    step: 1,
  },
];

function AuditForm({ initial, editable }: { initial: AuditSettings; editable: boolean }) {
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
      setProblem(parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; '));
      return;
    }
    setProblem(null);
    save.mutate(parsed.data);
  }

  return (
    <div className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        {AUDIT_FIELDS.map((f) => (
          <Field key={f.key} label={f.label} hint={f.hint}>
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
          label="Document alert days"
          hint="Comma-separated, e.g. 30, 7, 1. An alert is also raised on expiry."
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
        <p className="text-sm text-emerald-700">
          Saved. Fuel audits use the new thresholds from the next recompute.
        </p>
      )}
      {editable && (
        <div className="flex justify-end">
          <Button busy={save.isPending} onClick={submit}>
            Save thresholds
          </Button>
        </div>
      )}
    </div>
  );
}

function PayForm({ initial, editable }: { initial: PayRule; editable: boolean }) {
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
        <p className="text-sm text-emerald-700">
          Saved. Days that are already settled don’t change.
        </p>
      )}
      {editable && (
        <div className="flex justify-end">
          <Button
            busy={save.isPending}
            onClick={() => {
              const parsed = PayRuleSchema.safeParse(rule);
              if (!parsed.success) {
                setProblem('Check the pay rule values');
                return;
              }
              setProblem(null);
              save.mutate(rule);
            }}
          >
            Save default pay
          </Button>
        </div>
      )}
    </div>
  );
}

export function SettingsPage() {
  const auth = useAuth();
  const audit = useAuditSettings();
  const pay = useDefaultPayRule();
  return (
    <>
      <PageHeader
        title="Settings"
        description={auth.isOwner ? undefined : 'Only the owner can change settings.'}
      />
      <div className="space-y-4">
        <Card title="Audit thresholds">
          <QueryState query={audit}>
            {(a) => <AuditForm initial={a} editable={auth.isOwner} />}
          </QueryState>
        </Card>
        <Card title="Default driver pay">
          <p className="mb-4 text-sm text-slate-600">
            Used in settlements for every driver without their own pay rule.
          </p>
          <QueryState query={pay}>
            {(p) => <PayForm initial={p} editable={auth.isOwner} />}
          </QueryState>
        </Card>
      </div>
    </>
  );
}
