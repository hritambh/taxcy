import type { PayRule } from './api-types.js';
import { fmtInr } from './format.js';

/** A plain-language summary of a pay rule, e.g. "20% of quoted fare + driver allowance". */
export function describePayRule(rule: PayRule): string {
  const base = (() => {
    switch (rule.kind) {
      case 'none':
        return 'No pay in settlements';
      case 'percent_of_fare':
        return `${String(rule.percent)}% of ${rule.base === 'quoted' ? 'quoted fare' : 'fare incl. charges'}`;
      case 'per_trip':
        return `${fmtInr(rule.amountPaise)} per trip`;
      case 'per_km':
        return `${fmtInr(rule.paisePerKm)} per km`;
      case 'fixed_daily':
        return `${fmtInr(rule.amountPaise)} per working day`;
    }
  })();
  return rule.allowanceToDriver ? `${base} + driver allowance` : base;
}

/** Plain wording for who owes whom: positive means the driver hands money over. */
export function netPayableText(netPayablePaise: number): {
  text: string;
  tone: 'owes' | 'owed' | 'even';
} {
  if (netPayablePaise > 0)
    return { text: `Driver pays you ${fmtInr(netPayablePaise)}`, tone: 'owes' };
  if (netPayablePaise < 0)
    return { text: `You pay the driver ${fmtInr(-netPayablePaise)}`, tone: 'owed' };
  return { text: 'Nothing to hand over', tone: 'even' };
}
