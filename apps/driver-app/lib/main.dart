import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/db/database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(AppDatabase.onDevice())],
      child: const TaxcyDriverApp(),
    ),
  );
}
