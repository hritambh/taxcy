import { Injectable } from '@nestjs/common';
import { z } from 'zod';
import { OnJob, type JobEvent } from '../../platform/jobs/on-job.js';
import { Db } from '../../platform/prisma.service.js';
import { FuelAuditService } from './fuel-audit.service.js';

const Payload = z.object({ vehicleId: z.uuid() });

@Injectable()
export class FuelAuditJob {
  constructor(
    private readonly db: Db,
    private readonly audit: FuelAuditService,
  ) {}

  /** A fill was recorded or voided (possibly arriving late and out of order). */
  @OnJob('fuel.fill_recorded')
  async onFill(event: JobEvent): Promise<void> {
    await this.recompute(event);
  }

  /** Settings changed or an owner dismissed a fuel alert as a false alarm. */
  @OnJob('fuel.recompute')
  async onRecompute(event: JobEvent): Promise<void> {
    await this.recompute(event);
  }

  private async recompute(event: JobEvent): Promise<void> {
    if (!event.orgId) throw new Error(`${event.topic} without org`);
    const { vehicleId } = Payload.parse(event.payload);
    await this.db.tenant(event.orgId, (tx) => this.audit.recompute(tx, vehicleId));
  }
}
