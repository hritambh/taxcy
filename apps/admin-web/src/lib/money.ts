import { i18n } from '../i18n/index.js';
import type { PayRule } from './api-types.js';
import { fmtInr } from './format.js';

/** A plain-language summary of a pay rule, e.g. "20% of quoted fare + driver allowance". */
export function describePayRule(rule: PayRule): string {
  const t = i18n.t;
  const base = (() => {
    switch (rule.kind) {
      case 'none':
        return t('money.payRule.none');
      case 'percent_of_fare':
        return rule.base === 'quoted'
          ? t('money.payRule.percentOfQuoted', { percent: rule.percent })
          : t('money.payRule.percentOfExpected', { percent: rule.percent });
      case 'per_trip':
        return t('money.payRule.perTrip', { amount: fmtInr(rule.amountPaise) });
      case 'per_km':
        return t('money.payRule.perKm', { amount: fmtInr(rule.paisePerKm) });
      case 'fixed_daily':
        return t('money.payRule.fixedDaily', { amount: fmtInr(rule.amountPaise) });
    }
  })();
  return rule.allowanceToDriver ? t('money.payRule.withAllowance', { rule: base }) : base;
}

/** Plain wording for who owes whom: positive means the driver hands money over. */
export function netPayableText(netPayablePaise: number): {
  text: string;
  tone: 'owes' | 'owed' | 'even';
} {
  if (netPayablePaise > 0)
    return {
      text: i18n.t('money.driverPaysYou', { amount: fmtInr(netPayablePaise) }),
      tone: 'owes',
    };
  if (netPayablePaise < 0)
    return {
      text: i18n.t('money.youPayDriver', { amount: fmtInr(-netPayablePaise) }),
      tone: 'owed',
    };
  return { text: i18n.t('money.nothingToHandOver'), tone: 'even' };
}
