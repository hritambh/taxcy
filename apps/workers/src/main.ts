import { createBullBoard } from '@bull-board/api';
import { BullMQAdapter } from '@bull-board/api/bullMQAdapter';
import { ExpressAdapter } from '@bull-board/express';
import {
  APP_CONFIG,
  createWorkerContext,
  JobDispatcher,
  OutboxRelay,
  queueFor,
  SCHEDULES,
  type AppConfig,
  type JobEvent,
} from '@taxcy/api/worker';
import { Queue, Worker, type ConnectionOptions } from 'bullmq';
import express, { type RequestHandler } from 'express';
import { Logger } from 'nestjs-pino';

const RELAY_INTERVAL_MS = 1_000;
const DASHBOARD_PORT = Number(process.env['WORKERS_DASHBOARD_PORT'] ?? 3001);

const context = await createWorkerContext();
const logger = context.get(Logger);
const config = context.get<AppConfig>(APP_CONFIG);
const dispatcher = context.get(JobDispatcher);
const relay = context.get(OutboxRelay);

const redisUrl = new URL(config.REDIS_URL);
const connection: ConnectionOptions = {
  host: redisUrl.hostname,
  port: Number(redisUrl.port || 6379),
  ...(redisUrl.password ? { password: decodeURIComponent(redisUrl.password) } : {}),
  maxRetriesPerRequest: null,
};

// One queue per topic prefix (media, fuel, trips, …).
const queueNames = new Set(
  [...dispatcher.topics(), ...SCHEDULES.map((s) => s.topic)].map(queueFor),
);
const queues = new Map([...queueNames].map((name) => [name, new Queue(name, { connection })]));
const workers = [...queueNames].map(
  (name) =>
    new Worker(
      name,
      async (job) => {
        await dispatcher.dispatch(job.data as JobEvent);
      },
      { connection, concurrency: 5 },
    ),
);
for (const worker of workers) {
  worker.on('failed', (job, error) => {
    logger.error(
      { queue: worker.name, job: job?.name, attempts: job?.attemptsMade, err: error },
      'job failed',
    );
  });
}

for (const schedule of SCHEDULES) {
  const queue = queues.get(queueFor(schedule.topic));
  await queue?.upsertJobScheduler(
    schedule.topic,
    { pattern: schedule.pattern, tz: 'UTC' },
    {
      name: schedule.topic,
      data: { topic: schedule.topic, orgId: null, payload: {} } satisfies JobEvent,
    },
  );
}

// Outbox → BullMQ. jobId = outbox id, so a relay that crashes after enqueueing but
// before marking the row dispatched can't create a duplicate job.
let relaying = false;
const relayTimer = setInterval(() => {
  if (relaying) return;
  relaying = true;
  relay
    .drainOnce(async (event, id) => {
      const queue = queues.get(queueFor(event.topic));
      if (!queue) {
        logger.warn({ topic: event.topic }, 'no queue for outbox topic; dropping');
        return;
      }
      await queue.add(event.topic, event, {
        jobId: `outbox-${id}`,
        attempts: 5,
        backoff: { type: 'exponential', delay: 2_000 },
        removeOnComplete: 1_000,
        removeOnFail: 5_000,
      });
    })
    .catch((error: unknown) => {
      logger.error({ err: error }, 'outbox relay failed');
    })
    .finally(() => {
      relaying = false;
    });
}, RELAY_INTERVAL_MS);

const board = new ExpressAdapter();
board.setBasePath('/queues');
createBullBoard({
  queues: [...queues.values()].map((q) => new BullMQAdapter(q)),
  serverAdapter: board,
});
const dashboard = express()
  .use('/queues', board.getRouter() as RequestHandler)
  .listen(DASHBOARD_PORT);

logger.log(
  `workers: started; queues [${[...queueNames].join(', ')}]; handlers [${dispatcher.topics().join(', ')}]; dashboard http://localhost:${DASHBOARD_PORT}/queues`,
);

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.once(signal, () => {
    logger.log(`workers: ${signal}, shutting down`);
    clearInterval(relayTimer);
    dashboard.close();
    void Promise.all(workers.map((w) => w.close()))
      .then(() => Promise.all([...queues.values()].map((q) => q.close())))
      .then(() => context.close());
  });
}
