// BullMQ queues, the outbox relay and cron jobs are registered here starting in M0.4.
// Until then this is only the long-running process shell with graceful shutdown.
const keepAlive = setInterval(() => undefined, 60_000);
process.stdout.write('workers: started, no queues registered yet\n');

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.once(signal, () => {
    clearInterval(keepAlive);
    process.stdout.write(`workers: received ${signal}, shutting down\n`);
  });
}
