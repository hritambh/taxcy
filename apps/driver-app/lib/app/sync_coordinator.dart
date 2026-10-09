import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Keeps the outbox draining: on start, on connectivity changes, every 30 s, and
/// when the app returns to the foreground. Also runs the GPS recorder exactly
/// while a trip is started on this phone.
class SyncCoordinator extends ConsumerStatefulWidget {
  const SyncCoordinator({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<SyncCoordinator> createState() => _SyncCoordinatorState();
}

class _SyncCoordinatorState extends ConsumerState<SyncCoordinator>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!ref.read(backgroundWorkProvider)) return;
    WidgetsBinding.instance.addObserver(this);
    final engine = ref.read(syncEngineProvider);
    _connectivity = Connectivity().onConnectivityChanged.listen((results) {
      engine.setOnline(!results.every((r) => r == ConnectivityResult.none));
    });
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => engine.syncNow(),
    );
    unawaited(engine.syncNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(syncEngineProvider).syncNow());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_connectivity?.cancel());
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.read(backgroundWorkProvider)) {
      ref.listen(tripsProvider, (_, next) {
        final trips = next.value ?? const [];
        final recorder = ref.read(gpsRecorderProvider);
        final active = trips.where(
          (t) => t.trip.status == 'started' && t.conflict == null,
        );
        if (active.isEmpty) {
          unawaited(recorder.stop());
        } else {
          unawaited(recorder.start(active.first.trip.id));
        }
      });
    }
    return widget.child;
  }
}
