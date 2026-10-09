import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxcy_driver/core/media/photo_store.dart';

import 'support/fakes.dart';

void main() {
  group('DatabasePhotoStore (browser build)', () {
    test('keeps photo bytes until sign-out clears the database', () async {
      final db = memoryDb();
      addTearDown(db.close);
      final store = DatabasePhotoStore(db);
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);

      final ref = await store.save('photo-1', bytes);
      expect(await store.read(ref), bytes);

      // Retaking under the same id replaces the bytes.
      await store.save('photo-1', Uint8List.fromList([1]));
      expect(await store.read(ref), [1]);

      await db.clearAll();
      await expectLater(store.read(ref), throwsStateError);
    });
  });
}
