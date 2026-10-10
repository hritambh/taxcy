import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api/json.dart';
import '../db/database.dart';

/// Kinds of queued writes. Each maps to one API call in the sync engine.
abstract final class OutboxKind {
  /// Register → upload → confirm a photo. Payload: {photoId}.
  static const media = 'media';

  /// A trip the driver created. Payload: {body}; idempotent on body.id.
  static const tripCreate = 'trip.create';

  /// A trip state command. Payload: {tripId, command, body}; key = Idempotency-Key.
  static const tripCommand = 'trip.command';

  /// Payload: {tripId, body}; idempotent on body.id.
  static const tripCharge = 'trip.charge';
  static const tripCollection = 'trip.collection';

  /// Payload: {body}; idempotent on body.id.
  static const fuelFill = 'fuel.fill';
}

abstract final class OutboxState {
  static const pending = 'pending';

  /// The server rejected it for a reason retrying won't fix; shown to the driver.
  static const attention = 'attention';
}

class Outbox {
  Outbox(this.db, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;

  /// Queues a write and returns its key (also the Idempotency-Key for commands).
  Future<String> enqueue(
    String kind,
    JsonMap payload, {
    String? tripId,
    String? key,
  }) async {
    final itemKey = key ?? const Uuid().v4();
    await db
        .into(db.outboxItems)
        .insert(
          OutboxItemsCompanion.insert(
            key: itemKey,
            kind: kind,
            payload: jsonEncode(payload),
            tripId: Value(tripId),
            createdAt: _now(),
          ),
        );
    return itemKey;
  }

  Future<List<OutboxItem>> pending() =>
      (db.select(db.outboxItems)
            ..where((t) => t.state.equals(OutboxState.pending))
            ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
          .get();

  Future<bool> hasPendingFor(String tripId, {String? kind}) async {
    final query = db.select(db.outboxItems)
      ..where(
        (t) =>
            t.tripId.equals(tripId) &
            t.state.equals(OutboxState.pending) &
            (kind == null ? const Constant(true) : t.kind.equals(kind)),
      );
    return (await query.get()).isNotEmpty;
  }

  Future<void> remove(int seq) =>
      (db.delete(db.outboxItems)..where((t) => t.seq.equals(seq))).go();

  Future<void> scheduleRetry(OutboxItem item, DateTime at, String error) =>
      (db.update(db.outboxItems)..where((t) => t.seq.equals(item.seq))).write(
        OutboxItemsCompanion(
          attempts: Value(item.attempts + 1),
          nextAttemptAt: Value(at),
          lastError: Value(error),
        ),
      );

  Future<void> needsAttention(OutboxItem item, String error) =>
      (db.update(db.outboxItems)..where((t) => t.seq.equals(item.seq))).write(
        OutboxItemsCompanion(
          state: const Value(OutboxState.attention),
          attempts: Value(item.attempts + 1),
          lastError: Value(error),
        ),
      );

  /// Drops queued trip writes for a trip the server no longer accepts writes for.
  /// Photos still upload (the server keeps them as evidence), and so do fuel
  /// fills: the fuel was bought whatever happened to the trip.
  Future<int> dropTripWrites(String tripId) =>
      (db.delete(db.outboxItems)..where(
            (t) =>
                t.tripId.equals(tripId) &
                t.kind.isNotIn([OutboxKind.media, OutboxKind.fuelFill]) &
                t.state.equals(OutboxState.pending),
          ))
          .go();

  Stream<({int pending, int attention})> watchCounts() => db
      .select(db.outboxItems)
      .watch()
      .map(
        (rows) => (
          pending: rows.where((r) => r.state == OutboxState.pending).length,
          attention: rows.where((r) => r.state == OutboxState.attention).length,
        ),
      );

  Future<List<OutboxItem>> attentionItems() => (db.select(
    db.outboxItems,
  )..where((t) => t.state.equals(OutboxState.attention))).get();

  /// Lets the driver retry everything that needed attention (e.g. after fixing a photo).
  Future<void> retryAttention() =>
      (db.update(
        db.outboxItems,
      )..where((t) => t.state.equals(OutboxState.attention))).write(
        const OutboxItemsCompanion(
          state: Value(OutboxState.pending),
          nextAttemptAt: Value(null),
        ),
      );
}

JsonMap decodePayload(OutboxItem item) => asJsonMap(jsonDecode(item.payload));
