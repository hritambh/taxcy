import type { Prisma, TenantTx } from '@taxcy/db';

/**
 * Records a domain event in the caller's transaction. The workers' outbox relay
 * publishes it to BullMQ after commit, so jobs are never enqueued for rolled-back
 * work and never lost if the process dies right after commit.
 */
export async function publish(
  tx: TenantTx,
  topic: string,
  payload: Prisma.InputJsonValue,
): Promise<void> {
  await tx.outboxEvent.create({ data: { orgId: tx.orgId, topic, payload } });
}
