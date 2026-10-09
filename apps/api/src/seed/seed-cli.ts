import { createWorkerContext } from '../worker.js';
import { runSeed } from './seed.js';

const ctx = await createWorkerContext();
try {
  await runSeed(ctx);
} finally {
  await ctx.close();
}
