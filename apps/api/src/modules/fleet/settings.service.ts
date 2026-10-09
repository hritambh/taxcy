import { Injectable } from '@nestjs/common';
import { AuditSettings, PayRule } from '@taxcy/contracts';
import type { TenantTx } from '@taxcy/db';
import type { PayRule as DomainPayRule } from '@taxcy/domain';
import { definedOnly, type Patch } from '../../platform/patch.js';

// Compile-time check that the API's pay-rule schema matches the domain's type.
type Assert<T extends true> = T;
export type PayRuleMatchesDomain = Assert<PayRule extends DomainPayRule ? true : false>;

export interface OrgSettings {
  audit: AuditSettings;
  payRule: PayRule;
}

@Injectable()
export class SettingsService {
  async get(tx: TenantTx): Promise<OrgSettings> {
    const row = await tx.orgSettings.findUniqueOrThrow({ where: { orgId: tx.orgId } });
    return {
      audit: {
        fuelKSigma: row.fuelKSigma,
        fuelMinCycles: row.fuelMinCycles,
        fuelPctThreshold: row.fuelPctThreshold,
        fuelEwmaAlpha: row.fuelEwmaAlpha,
        odoGpsTolerancePct: row.odoGpsTolerancePct,
        docAlertDays: row.docAlertDays,
      },
      payRule: PayRule.parse(row.driverPayRule),
    };
  }

  async updateAudit(tx: TenantTx, patch: Patch<AuditSettings>): Promise<AuditSettings> {
    await tx.orgSettings.update({ where: { orgId: tx.orgId }, data: definedOnly(patch) });
    return (await this.get(tx)).audit;
  }

  async updatePayRule(tx: TenantTx, rule: PayRule): Promise<PayRule> {
    await tx.orgSettings.update({ where: { orgId: tx.orgId }, data: { driverPayRule: rule } });
    return rule;
  }
}
