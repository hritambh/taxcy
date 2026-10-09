import type { PayRule } from '../lib/api-types.js';
import { paiseToRupeesInput, rupeesToPaise } from '../lib/format.js';
import { Field, Input, Select } from './ui.js';

type Kind = PayRule['kind'];

const KINDS: { kind: Kind; label: string }[] = [
  { kind: 'none', label: 'None (salaried, paid outside Taxcy)' },
  { kind: 'percent_of_fare', label: 'Percent of fare' },
  { kind: 'per_trip', label: 'Fixed amount per trip' },
  { kind: 'per_km', label: 'Per km driven' },
  { kind: 'fixed_daily', label: 'Fixed amount per working day' },
];

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
      <Field label="How the driver is paid" className="sm:col-span-2">
        {(props) => (
          <Select
            {...props}
            disabled={disabled}
            value={value.kind}
            onChange={(e) => {
              onChange(defaultsFor(e.target.value as Kind, value.allowanceToDriver));
            }}
          >
            {KINDS.map((k) => (
              <option key={k.kind} value={k.kind}>
                {k.label}
              </option>
            ))}
          </Select>
        )}
      </Field>
      {value.kind === 'percent_of_fare' && (
        <>
          <Field label="Percent">
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
          <Field label="Of">
            {(props) => (
              <Select
                {...props}
                disabled={disabled}
                value={value.base}
                onChange={(e) => {
                  onChange({ ...value, base: e.target.value as 'quoted' | 'expected' });
                }}
              >
                <option value="quoted">Quoted fare</option>
                <option value="expected">Fare including charges</option>
              </Select>
            )}
          </Field>
        </>
      )}
      {value.kind === 'per_trip' &&
        rupeeField('Amount per trip (₹)', value.amountPaise, (amountPaise) => {
          onChange({ ...value, amountPaise });
        })}
      {value.kind === 'per_km' &&
        rupeeField('Rate per km (₹)', value.paisePerKm, (paisePerKm) => {
          onChange({ ...value, paisePerKm });
        })}
      {value.kind === 'fixed_daily' &&
        rupeeField('Amount per working day (₹)', value.amountPaise, (amountPaise) => {
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
          Driver allowance goes to the driver
          <span className="block text-xs text-slate-500">
            The bata a customer pays is added to the driver’s earnings.
          </span>
        </span>
      </label>
    </div>
  );
}
