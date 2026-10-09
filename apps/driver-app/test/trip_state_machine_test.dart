import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/core/api/json.dart';
import 'package:taxcy_driver/core/domain/trip_state_machine.dart';

/// Every decision made by the TypeScript state machine (libs/domain), exported by
/// `bun run --cwd libs/domain fixtures`. The Dart port must agree on all of them.
final _fixture = asJsonMap(
  jsonDecode(
    File('../../libs/domain/fixtures/trip-transitions.json').readAsStringSync(),
  ),
);

TripState _state(JsonMap json) => TripState(
  json.str('status'),
  cancellationPending: json.boolean('cancellationPending'),
);

void main() {
  test('the transition table matches the TypeScript one', () {
    final ts = _fixture.obj('transitions');
    expect(ts.keys.toSet(), tripTransitions.keys.toSet());
    for (final MapEntry(key: command, value: rule) in tripTransitions.entries) {
      final other = ts.obj(command);
      expect(other.strings('from'), rule.from, reason: command);
      expect(other.str('to'), rule.to ?? 'same', reason: command);
      expect(
        other.strings('actors').map(tripActorFromName).toList(),
        rule.actors,
        reason: command,
      );
      expect(
        other['cancellationPending'],
        rule.cancellationPending,
        reason: command,
      );
    }
  });

  test('allowedCommands agrees for every state', () {
    for (final entry in _fixture.objects('allowed')) {
      final state = _state(entry.obj('state'));
      expect(
        allowedCommands(state),
        entry.strings('commands'),
        reason: '${state.status}/${state.cancellationPending}',
      );
    }
  });

  test('decideTransition agrees on every exported case', () {
    final cases = _fixture.objects('cases');
    expect(cases, hasLength(2112));
    for (final c in cases) {
      final state = _state(c.obj('state'));
      final actors = c.strings('actors').map(tripActorFromName).toList();
      final expected = c.obj('expected');
      final decision = decideTransition(state, c.str('command'), actors);
      final label =
          '${state.status}/${state.cancellationPending} ${c.str('command')} by ${c.strings('actors')}';
      if (expected.boolean('ok')) {
        expect(decision, isA<Allowed>(), reason: label);
        expect((decision as Allowed).to, expected.str('to'), reason: label);
      } else {
        expect(decision, isA<Rejected>(), reason: label);
        final rejected = decision as Rejected;
        expect(rejected.error, expected.str('error'), reason: label);
        expect(rejected.allowed, expected.strings('allowed'), reason: label);
      }
    }
  });
}
