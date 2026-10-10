import { useTranslation } from 'react-i18next';
import type { PayRule } from '../lib/api-types.js';
import { paiseToRupeesInput, rupeesToPaise } from '../lib/format.js';
import { Field, Input, Select } from './ui.js';

type Kind = PayRule['kind'];

const KINDS: Kind[] = ['none', 'percent_of_fare', 'per_trip', 'per_km', 'fixed_daily'];

function defaultsFor(kind: Kind, allowanceToDriver: boolean): PayRule {
  switch (kind) {
    case 'none':
      return { kind, allowanceToDriver };
    case 'percent_of_fare':
      return { kind, percent: 20, base: 'quoted', allowanceToDriver };
    case 'per_trip':
      return { kind, amountPaise: 30_000, allowanceToDriver };
    case 'per_km':
      return { kind, paisePerKm: 200, allowanceToDriver };
    case 'fixed_daily':
      return { kind, amountPaise: 80_000, allowanceToDriver };
  }
}

/** Edits a driver pay rule. Amounts are typed in rupees and kept in paise. */
export function PayRuleEditor({
  value,
  onChange,
  disabled,
}: {
  value: PayRule;
  onChange: (rule: PayRule) => void;
  disabled?: boolean;
}) {
  const { t } = useTranslation();
  const rupeeField = (label: string, paise: number, set: (p: number) => void) => (
    <Field label={label}>
      {(props) => (
        <Input
          {...props}
          inputMode="decimal"
          disabled={disabled}
          defaultValue={paiseToRupeesInput(paise)}
          onChange={(e) => {
            const parsed = rupeesToPaise(e.target.value);
            if (parsed !== null) set(parsed);
          }}
        />
      )}
    </Field>
  );

  return (
    <div className="grid gap-4 sm:grid-cols-2">
      <Field label={t('people.payRule.howPaid')} className="sm:col-span-2">
        {(props) => (
          <Select
            {...props}
            disabled={disabled}
            value={value.kind}
            onChange={(e) => {
              onChange(defaultsFor(e.target.value as Kind, value.allowanceToDriver));
            }}
          >
            {KINDS.map((kind) => (
              <option key={kind} value={kind}>
                {t(`enums.payRuleKind.${kind}`)}
              </option>
            ))}
          </Select>
        )}
      </Field>
      {value.kind === 'percent_of_fare' && (
        <>
          <Field label={t('people.payRule.percent')}>
            {(props) => (
              <Input
                {...props}
                type="number"
                min={0}
                max={100}
                step={0.5}
                disabled={disabled}
                value={value.percent}
                onChange={(e) => {
                  onChange({ ...value, percent: Number(e.target.value) });
                }}
              />
            )}
          </Field>
          <Field label={t('people.payRule.of')}>
            {(props) => (
              <Select
                {...props}
                disabled={disabled}
                value={value.base}
                onChange={(e) => {
                  onChange({ ...value, base: e.target.value as 'quoted' | 'expected' });
                }}
              >
                <option value="quoted">{t('enums.payBase.quoted')}</option>
                <option value="expected">{t('enums.payBase.expected')}</option>
              </Select>
            )}
          </Field>
        </>
      )}
      {value.kind === 'per_trip' &&
        rupeeField(t('people.payRule.amountPerTrip'), value.amountPaise, (amountPaise) => {
          onChange({ ...value, amountPaise });
        })}
      {value.kind === 'per_km' &&
        rupeeField(t('people.payRule.ratePerKm'), value.paisePerKm, (paisePerKm) => {
          onChange({ ...value, paisePerKm });
        })}
      {value.kind === 'fixed_daily' &&
        rupeeField(t('people.payRule.amountPerDay'), value.amountPaise, (amountPaise) => {
          onChange({ ...value, amountPaise });
        })}
      <label className="flex items-start gap-2 text-sm sm:col-span-2">
        <input
          type="checkbox"
          className="mt-0.5"
          disabled={disabled}
          checked={value.allowanceToDriver}
          onChange={(e) => {
            onChange({ ...value, allowanceToDriver: e.target.checked });
          }}
        />
        <span>
          {t('people.payRule.allowanceToDriver')}
          <span className="block text-xs text-slate-500">{t('people.payRule.allowanceHint')}</span>
        </span>
      </label>
    </div>
  );
}
