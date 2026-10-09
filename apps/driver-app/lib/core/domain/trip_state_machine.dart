// Dart port of libs/domain/src/trips/state-machine.ts. The app applies transitions
// offline with it; test/trip_state_machine_test.dart checks it against every case
// exported from the TypeScript implementation (libs/domain/fixtures).

enum TripActor { staff, assignedDriver, requester, system }

TripActor tripActorFromName(String name) => switch (name) {
  'staff' => TripActor.staff,
  'assigned_driver' => TripActor.assignedDriver,
  'requester' => TripActor.requester,
  'system' => TripActor.system,
  _ => throw ArgumentError('Unknown actor $name'),
};

class TransitionRule {
  const TransitionRule({
    required this.from,
    required this.to,
    required this.actors,
    this.cancellationPending,
  });

  final List<String> from;

  /// Target status, or null to keep the current one.
  final String? to;
  final List<TripActor> actors;
  final bool? cancellationPending;
}

const tripTransitions = <String, TransitionRule>{
  'assign': TransitionRule(
    from: ['created'],
    to: 'assigned',
    actors: [TripActor.staff],
  ),
  'reassign': TransitionRule(
    from: ['assigned'],
    to: 'assigned',
    actors: [TripActor.staff],
  ),
  'unassign': TransitionRule(
    from: ['assigned'],
    to: 'created',
    actors: [TripActor.staff],
  ),
  'start': TransitionRule(
    from: ['assigned'],
    to: 'started',
    actors: [TripActor.assignedDriver, TripActor.staff],
  ),
  'end': TransitionRule(
    from: ['started'],
    to: 'ended',
    actors: [TripActor.assignedDriver, TripActor.staff],
  ),
  'requestCancel': TransitionRule(
    from: ['started'],
    to: null,
    actors: [TripActor.assignedDriver, TripActor.staff],
    cancellationPending: false,
  ),
  'approveCancel': TransitionRule(
    from: ['started'],
    to: 'cancelled',
    actors: [TripActor.staff],
    cancellationPending: true,
  ),
  'rejectCancel': TransitionRule(
    from: ['started'],
    to: null,
    actors: [TripActor.staff],
    cancellationPending: true,
  ),
  'withdrawCancel': TransitionRule(
    from: ['started'],
    to: null,
    actors: [TripActor.requester, TripActor.staff],
    cancellationPending: true,
  ),
  'cancel': TransitionRule(
    from: ['created', 'assigned'],
    to: 'cancelled',
    actors: [TripActor.staff],
  ),
  'settle': TransitionRule(
    from: ['ended'],
    to: 'settled',
    actors: [TripActor.system],
  ),
};

class TripState {
  const TripState(this.status, {this.cancellationPending = false});
  final String status;
  final bool cancellationPending;
}

sealed class Decision {
  const Decision();
}

class Allowed extends Decision {
  const Allowed(this.to);
  final String to;
}

class Rejected extends Decision {
  const Rejected(this.error, this.message, this.allowed);

  /// ILLEGAL_TRANSITION, TRIP_CANCELLED, CANCELLATION_PENDING or FORBIDDEN_ROLE.
  final String error;
  final String message;
  final List<String> allowed;
}

List<String> allowedCommands(TripState state) => [
  for (final entry in tripTransitions.entries)
    if (entry.value.from.contains(state.status) &&
        (entry.value.cancellationPending == null ||
            entry.value.cancellationPending == state.cancellationPending))
      entry.key,
];

Decision decideTransition(
  TripState state,
  String command,
  List<TripActor> actors,
) {
  final rule = tripTransitions[command];
  if (rule == null) throw ArgumentError('Unknown command $command');
  final allowed = allowedCommands(state);

  if (!rule.from.contains(state.status)) {
    if (state.status == 'cancelled') {
      return Rejected(
        'TRIP_CANCELLED',
        'This trip has been cancelled',
        allowed,
      );
    }
    if (command == 'cancel' && state.status == 'started') {
      return Rejected(
        'ILLEGAL_TRANSITION',
        'A started trip can only be cancelled through a cancellation request',
        allowed,
      );
    }
    return Rejected(
      'ILLEGAL_TRANSITION',
      'Cannot $command a trip that is ${state.status}',
      allowed,
    );
  }
  if (rule.cancellationPending == false && state.cancellationPending) {
    return Rejected(
      'CANCELLATION_PENDING',
      'A cancellation request is already pending for this trip',
      allowed,
    );
  }
  if (rule.cancellationPending == true && !state.cancellationPending) {
    return Rejected(
      'ILLEGAL_TRANSITION',
      'There is no pending cancellation request',
      allowed,
    );
  }
  if (!rule.actors.any(actors.contains)) {
    return Rejected(
      'FORBIDDEN_ROLE',
      'You are not allowed to $command this trip',
      allowed,
    );
  }
  return Allowed(rule.to ?? state.status);
}
