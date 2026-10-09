import '../db/database.dart';
import 'photo_store.dart';

/// Browsers have no file system for the app, so photos live in the local database.
PhotoStore platformPhotoStore(AppDatabase db) => DatabasePhotoStore(db);

/// The camera's capture is an in-memory blob in the browser; nothing to delete.
Future<void> discardCameraFile(String path) async {}
