import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../db/database.dart';

/// Keeps photo bytes on the device until they're uploaded. Photos.path holds the
/// reference [save] returns: a file path on phones, a database key in the browser.
abstract interface class PhotoStore {
  Future<String> save(String id, Uint8List bytes);
  Future<Uint8List> read(String ref);
}

/// Browser storage: the bytes go in the local database (IndexedDB/OPFS-backed),
/// since a web app has no file system to write to.
class DatabasePhotoStore implements PhotoStore {
  DatabasePhotoStore(this.db);

  final AppDatabase db;

  @override
  Future<String> save(String id, Uint8List bytes) async {
    await db
        .into(db.photoBlobs)
        .insertOnConflictUpdate(
          PhotoBlobsCompanion.insert(id: id, bytes: bytes),
        );
    return id;
  }

  @override
  Future<Uint8List> read(String ref) async {
    final row = await (db.select(
      db.photoBlobs,
    )..where((b) => b.id.equals(ref))).getSingleOrNull();
    if (row == null) throw StateError('Photo $ref is no longer stored');
    return row.bytes;
  }
}
