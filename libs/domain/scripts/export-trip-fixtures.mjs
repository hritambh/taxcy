// Exports the trip transition table and every decision the TypeScript state machine
// makes, so the Flutter driver app can assert its Dart port agrees case by case.
// Run after `build`: bun run --cwd libs/domain fixtures
import { writeFileSync } from 'node:fs';
import { allowedCommands, decideTransition, TRIP_TRANSITIONS } from '../dist/index.js';

const STATUSES = ['created', 'assigned', 'started', 'ended', 'settled', 'cancelled'];
const ACTORS = ['staff', 'assigned_driver', 'requester', 'system'];
const COMMANDS = Object.keys(TRIP_TRANSITIONS);

// Every subset of actors (including none).
const actorSets = Array.from({ length: 1 << ACTORS.length }, (_, mask) =>
  ACTORS.filter((_, i) => mask & (1 << i)),
);

const cases = [];
const allowed = [];
for (const status of STATUSES) {
  for (const cancellationPending of [false, true]) {
    const state = { status, cancellationPending };
    allowed.push({ state, commands: allowedCommands(state) });
    for (const command of COMMANDS) {
      for (const actors of actorSets) {
        const decision = decideTransition(state, command, actors);
        cases.push({
          state,
          command,
          actors,
          expected: decision.ok
            ? { ok: true, to: decision.to }
            : { ok: false, error: decision.error, allowed: decision.allowed },
        });
      }
    }
  }
}

const out = new URL('../fixtures/trip-transitions.json', import.meta.url);
writeFileSync(out, `${JSON.stringify({ transitions: TRIP_TRANSITIONS, allowed, cases })}\n`);
process.stdout.write(`wrote ${cases.length} cases to fixtures/trip-transitions.json\n`);
