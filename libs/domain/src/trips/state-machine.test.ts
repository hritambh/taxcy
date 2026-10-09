import { describe, expect, it } from 'vitest';
import {
  allowedCommands,
  decideTransition,
  TRIP_TRANSITIONS,
  type TripActor,
  type TripCommand,
  type TripState,
} from './state-machine.js';

const s = (status: TripState['status'], cancellationPending = false): TripState => ({
  status,
  cancellationPending,
});
const staff: TripActor[] = ['staff'];
const driver: TripActor[] = ['assigned_driver'];

describe('decideTransition: happy path', () => {
  it.each<[TripState, TripCommand, TripActor[], string]>([
    [s('created'), 'assign', staff, 'assigned'],
    [s('assigned'), 'reassign', staff, 'assigned'],
    [s('assigned'), 'unassign', staff, 'created'],
    [s('assigned'), 'start', driver, 'started'],
    [s('assigned'), 'start', staff, 'started'],
    [s('started'), 'end', driver, 'ended'],
    [s('started', true), 'end', driver, 'ended'],
    [s('ended'), 'settle', ['system'], 'settled'],
    [s('created'), 'cancel', staff, 'cancelled'],
    [s('assigned'), 'cancel', staff, 'cancelled'],
    [s('started'), 'requestCancel', driver, 'started'],
    [s('started', true), 'approveCancel', staff, 'cancelled'],
    [s('started', true), 'rejectCancel', staff, 'started'],
    [s('started', true), 'withdrawCancel', ['requester'], 'started'],
  ])('%o %s by %o → %s', (state, command, actors, to) => {
    expect(decideTransition(state, command, actors)).toEqual({ ok: true, to });
  });
});

describe('decideTransition: rejections', () => {
  it.each<[string, TripState, TripCommand, TripActor[], string]>([
    ['start a trip that is not assigned', s('created'), 'start', staff, 'ILLEGAL_TRANSITION'],
    ['end before starting', s('assigned'), 'end', driver, 'ILLEGAL_TRANSITION'],
    ['start after the server cancelled it', s('cancelled'), 'start', driver, 'TRIP_CANCELLED'],
    ['end after cancellation was approved', s('cancelled'), 'end', driver, 'TRIP_CANCELLED'],
    ['cancel a started trip directly', s('started'), 'cancel', staff, 'ILLEGAL_TRANSITION'],
    [
      'request cancellation twice',
      s('started', true),
      'requestCancel',
      driver,
      'CANCELLATION_PENDING',
    ],
    ['approve with no request', s('started'), 'approveCancel', staff, 'ILLEGAL_TRANSITION'],
    ['driver approves own request', s('started', true), 'approveCancel', driver, 'FORBIDDEN_ROLE'],
    ['driver assigns', s('created'), 'assign', driver, 'FORBIDDEN_ROLE'],
    ['another driver starts', s('assigned'), 'start', [], 'FORBIDDEN_ROLE'],
    ['staff settles by hand', s('ended'), 'settle', staff, 'FORBIDDEN_ROLE'],
    ['edit a settled trip', s('settled'), 'reassign', staff, 'ILLEGAL_TRANSITION'],
  ])('cannot %s', (_name, state, command, actors, error) => {
    const decision = decideTransition(state, command, actors);
    expect(decision.ok).toBe(false);
    if (!decision.ok) expect(decision.error).toBe(error);
  });

  it('explains how to cancel a started trip', () => {
    const decision = decideTransition(s('started'), 'cancel', staff);
    expect(decision).toMatchObject({
      ok: false,
      message: expect.stringContaining('cancellation request') as string,
    });
  });
});

describe('allowedCommands', () => {
  it.each<[TripState, TripCommand[]]>([
    [s('created'), ['assign', 'cancel']],
    [s('assigned'), ['reassign', 'unassign', 'start', 'cancel']],
    [s('started'), ['end', 'requestCancel']],
    [s('started', true), ['end', 'approveCancel', 'rejectCancel', 'withdrawCancel']],
    [s('ended'), ['settle']],
    [s('settled'), []],
    [s('cancelled'), []],
  ])('%o → %o', (state, commands) => {
    expect(allowedCommands(state)).toEqual(commands);
  });

  it('is plain data that serialises for the driver app', () => {
    expect(JSON.parse(JSON.stringify(TRIP_TRANSITIONS))).toEqual(TRIP_TRANSITIONS);
  });
});
