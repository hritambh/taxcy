export type TripStatus = 'created' | 'assigned' | 'started' | 'ended' | 'settled' | 'cancelled';

export type TripCommand =
  | 'assign'
  | 'reassign'
  | 'unassign'
  | 'start'
  | 'end'
  | 'requestCancel'
  | 'approveCancel'
  | 'rejectCancel'
  | 'withdrawCancel'
  | 'cancel'
  | 'settle';

/**
 * Who may issue a command: staff (owner/manager), the trip's assigned driver, the
 * person who filed the pending cancellation request, or the system.
 */
export type TripActor = 'staff' | 'assigned_driver' | 'requester' | 'system';

export interface TransitionRule {
  from: readonly TripStatus[];
  /** Target status; 'same' keeps the status (e.g. a cancellation request on a started trip). */
  to: TripStatus | 'same';
  actors: readonly TripActor[];
  /** Whether a pending cancellation request must (true) or must not (false) exist. */
  cancellationPending?: boolean;
}

/**
 * The trip lifecycle as plain data. It's exported as JSON for the Flutter driver app
 * (which applies transitions offline), and both implementations run the same
 * fixture cases (see tripTransitionCases).
 */
export const TRIP_TRANSITIONS: Readonly<Record<TripCommand, TransitionRule>> = {
  assign: { from: ['created'], to: 'assigned', actors: ['staff'] },
  reassign: { from: ['assigned'], to: 'assigned', actors: ['staff'] },
  unassign: { from: ['assigned'], to: 'created', actors: ['staff'] },
  start: { from: ['assigned'], to: 'started', actors: ['assigned_driver', 'staff'] },
  // Ending a trip with a pending cancellation request withdraws the request.
  end: { from: ['started'], to: 'ended', actors: ['assigned_driver', 'staff'] },
  requestCancel: {
    from: ['started'],
    to: 'same',
    actors: ['assigned_driver', 'staff'],
    cancellationPending: false,
  },
  approveCancel: {
    from: ['started'],
    to: 'cancelled',
    actors: ['staff'],
    cancellationPending: true,
  },
  rejectCancel: { from: ['started'], to: 'same', actors: ['staff'], cancellationPending: true },
  withdrawCancel: {
    from: ['started'],
    to: 'same',
    actors: ['requester', 'staff'],
    cancellationPending: true,
  },
  cancel: { from: ['created', 'assigned'], to: 'cancelled', actors: ['staff'] },
  settle: { from: ['ended'], to: 'settled', actors: ['system'] },
};

export interface TripState {
  status: TripStatus;
  cancellationPending: boolean;
}

export type TransitionError =
  'ILLEGAL_TRANSITION' | 'TRIP_CANCELLED' | 'CANCELLATION_PENDING' | 'FORBIDDEN_ROLE';

export type Decision =
  | { ok: true; to: TripStatus }
  | { ok: false; error: TransitionError; message: string; allowed: TripCommand[] };

/** Commands that are valid for this state (ignoring who's asking). */
export function allowedCommands(state: TripState): TripCommand[] {
  return (Object.keys(TRIP_TRANSITIONS) as TripCommand[]).filter((command) => {
    const rule = TRIP_TRANSITIONS[command];
    return (
      rule.from.includes(state.status) &&
      (rule.cancellationPending === undefined ||
        rule.cancellationPending === state.cancellationPending)
    );
  });
}

/**
 * Decides whether `actors` (every role the caller holds for this trip) may apply
 * `command` to a trip in `state`, and what status results.
 */
export function decideTransition(
  state: TripState,
  command: TripCommand,
  actors: readonly TripActor[],
): Decision {
  const rule = TRIP_TRANSITIONS[command];
  const allowed = allowedCommands(state);
  const fail = (error: TransitionError, message: string): Decision => ({
    ok: false,
    error,
    message,
    allowed,
  });

  if (!rule.from.includes(state.status)) {
    if (state.status === 'cancelled') return fail('TRIP_CANCELLED', 'This trip has been cancelled');
    if (command === 'cancel' && state.status === 'started') {
      return fail(
        'ILLEGAL_TRANSITION',
        'A started trip can only be cancelled through a cancellation request',
      );
    }
    return fail('ILLEGAL_TRANSITION', `Cannot ${command} a trip that is ${state.status}`);
  }
  if (rule.cancellationPending === false && state.cancellationPending) {
    return fail('CANCELLATION_PENDING', 'A cancellation request is already pending for this trip');
  }
  if (rule.cancellationPending === true && !state.cancellationPending) {
    return fail('ILLEGAL_TRANSITION', 'There is no pending cancellation request');
  }
  if (!rule.actors.some((a) => actors.includes(a))) {
    return fail('FORBIDDEN_ROLE', `Only ${rule.actors.join(' or ')} can ${command} this trip`);
  }
  return { ok: true, to: rule.to === 'same' ? state.status : rule.to };
}
