import { SetMetadata } from '@nestjs/common';

export const ON_JOB = Symbol('ON_JOB');

/**
 * Marks a provider method as the handler for an outbox topic or schedule. The
 * workers app (and the integration-test runner) discover handlers by this metadata.
 * Handlers must be idempotent: jobs can be retried or delivered twice.
 */
export const OnJob = (topic: string): MethodDecorator => SetMetadata(ON_JOB, topic);

export interface JobEvent {
  topic: string;
  orgId: string | null;
  payload: unknown;
}

/** Queue a topic is routed to: its prefix, e.g. media.uploaded → media. */
export const queueFor = (topic: string): string => topic.split('.')[0] ?? 'default';

/** Recurring system jobs (handlers receive orgId null). Patterns are UTC cron. */
export const SCHEDULES: readonly { topic: string; pattern: string; description: string }[] = [
  {
    topic: 'fleet.document_expiry_scan',
    pattern: '30 0 * * *',
    description: 'Document expiry alerts, 06:00 IST',
  },
];
