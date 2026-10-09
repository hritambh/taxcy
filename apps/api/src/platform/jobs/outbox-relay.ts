import { Injectable } from '@nestjs/common';
import { Db } from '../prisma.service.js';
import type { JobEvent } from './on-job.js';

interface OutboxRow {
  id: bigint;
  org_id: string | null;
  topic: string;
  payload: unknown;
}

/**
 * Moves committed outbox rows to a publisher (BullMQ in the workers app, direct
 * dispatch in tests). Rows are locked with SKIP LOCKED so several relays can run.
 * A row is marked dispatched only after `publish` succeeds.
 */
@Injectable()
export class OutboxRelay {
  constructor(private readonly db: Db) {}

  /** Publishes up to `batch` events; returns how many were published. */
  async drainOnce(
    publish: (event: JobEvent, id: string) => Promise<void>,
    batch = 100,
  ): Promise<number> {
    return this.db.system(async (tx) => {
      const rows = await tx.$queryRaw<OutboxRow[]>`
        SELECT id, org_id, topic, payload FROM outbox
        WHERE dispatched_at IS NULL
        ORDER BY id
        LIMIT ${batch}
        FOR UPDATE SKIP LOCKED`;
      for (const row of rows) {
        await publish(
          { topic: row.topic, orgId: row.org_id, payload: row.payload },
          row.id.toString(),
        );
      }
      if (rows.length) {
        await tx.$executeRaw`UPDATE outbox SET dispatched_at = now() WHERE id = ANY(${rows.map((r) => r.id)})`;
      }
      return rows.length;
    });
  }
}
