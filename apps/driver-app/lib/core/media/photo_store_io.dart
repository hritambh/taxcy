import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';
import 'photo_store.dart';

/// Phones keep photos as files in the app's documents directory.
PhotoStore platformPhotoStore(AppDatabase db) => FilePhotoStore();

/// Removes the camera plugin's temporary file once the photo has been stored.
Future<void> discardCameraFile(String path) async {
  try {
    await File(path).delete();
  } on FileSystemException {
    // Already gone; the OS cleans its temp directory anyway.
  }
}

class FilePhotoStore implements PhotoStore {
  @override
  Future<String> save(String id, Uint8List bytes) async {
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'photos'),
    );
    await dir.create(recursive: true);
    final path = p.join(dir.path, '$id.jpg');
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  @override
  Future<Uint8List> read(String ref) => File(ref).readAsBytes();
}
