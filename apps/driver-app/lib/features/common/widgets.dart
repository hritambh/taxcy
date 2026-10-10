import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/media/captured_photo.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/outbox.dart';
import '../../l10n/app_localizations.dart';
import 'errors.dart';
import 'format.dart';

/// 🟢 Synced / 🟡 N pending / 🔴 Offline, plus a tap-through for items that need attention.
class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  static String label(AppLocalizations l, SyncStatus s) {
    if (!s.online) {
      return s.pending == 0
          ? l.syncOffline
          : l.syncOfflineSaved(count: s.pending);
    }
    if (s.pending > 0) return l.syncPending(count: s.pending);
    return l.synced;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider).value;
    if (status == null) return const SizedBox.shrink();
    final l = context.l10n;
    final (Color color, IconData icon) = !status.online
        ? (Colors.red.shade700, Icons.cloud_off)
        : status.pending > 0
        ? (Colors.amber.shade800, Icons.cloud_upload)
        : (TaxcyColors.blue700, Icons.cloud_done);
    return Material(
      color: color.withValues(alpha: 0.12),
      child: InkWell(
        onTap: status.attention > 0 ? () => _showAttention(context, ref) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color, semanticLabel: l.syncStatus),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label(l, status),
                  key: const Key('sync-status-label'),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              if (status.attention > 0)
                Text(
                  l.needAttention(count: status.attention),
                  style: TextStyle(color: Colors.red.shade700),
                ),
              if (status.syncing)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAttention(BuildContext context, WidgetRef ref) async {
    final engine = ref.read(syncEngineProvider);
    final items = await engine.outbox.attentionItems();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(sheet.l10n.attentionTitle),
              subtitle: Text(sheet.l10n.attentionSubtitle),
            ),
            for (final item in items)
              ListTile(
                dense: true,
                leading: const Icon(Icons.error_outline),
                title: Text(outboxKindLabel(sheet.l10n, item.kind)),
                subtitle: Text(outboxErrorText(sheet.l10n, item.lastError)),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () async {
                  await engine.outbox.retryAttention();
                  unawaited(engine.syncNow());
                  if (sheet.mounted) Navigator.of(sheet).pop();
                },
                child: Text(sheet.l10n.retryAll),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows server-wins conflicts (trip cancelled or reassigned while offline).
class SyncNoticeListener extends ConsumerStatefulWidget {
  const SyncNoticeListener({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<SyncNoticeListener> createState() => _SyncNoticeListenerState();
}

class _SyncNoticeListenerState extends ConsumerState<SyncNoticeListener> {
  StreamSubscription<SyncNotice>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(syncEngineProvider).notices.listen((notice) {
      if (!mounted) return;
      final l = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notice.code == 'TRIP_CANCELLED'
                ? l.conflictCancelledBanner
                : l.conflictReassignedBanner,
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'started' => Colors.blue,
      'assigned' => Colors.indigo,
      'ended' || 'settled' => Colors.green,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };
    return Chip(
      label: Text(statusLabel(context.l10n, status)),
      labelStyle: TextStyle(color: color.shade800, fontSize: 12),
      backgroundColor: color.shade50,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// A required photo slot: shows a thumbnail once taken; tap to (re)take with the camera.
class PhotoField extends ConsumerWidget {
  const PhotoField({
    required this.kind,
    required this.label,
    required this.photo,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final String kind;
  final String label;
  final CapturedPhoto? photo;
  final ValueChanged<CapturedPhoto> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = photo;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          if (current == null)
            const Icon(Icons.photo_camera_outlined)
          else
            _Thumbnail(key: ValueKey(current.id), photoRef: current.path),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              current == null
                  ? context.l10n.noPhotoYet
                  : context.l10n.photoTaken,
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final taken = await ref.read(photoCaptureProvider)(context, kind);
              if (taken != null) onChanged(taken);
            },
            icon: const Icon(Icons.camera_alt),
            label: Text(
              current == null ? context.l10n.takePhoto : context.l10n.retake,
            ),
          ),
        ],
      ),
    );
  }
}

/// The stored photo, or a tick if it can't be read back.
class _Thumbnail extends ConsumerStatefulWidget {
  const _Thumbnail({required this.photoRef, super.key});

  final String photoRef;

  @override
  ConsumerState<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends ConsumerState<_Thumbnail> {
  late final Future<Uint8List> _bytes = ref
      .read(photoStoreProvider)
      .read(widget.photoRef);

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null || data.isEmpty) {
        return const Icon(Icons.check_circle, color: Colors.green);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(data, width: 64, height: 48, fit: BoxFit.cover),
      );
    },
  );
}

/// What an outbox item is, for the "could not be sent" list.
String outboxKindLabel(AppLocalizations l, String kind) => switch (kind) {
  OutboxKind.media => l.outboxMedia,
  OutboxKind.tripCommand => l.outboxTripCommand,
  OutboxKind.tripCreate => l.outboxTripCreate,
  OutboxKind.tripCharge => l.outboxTripCharge,
  OutboxKind.tripCollection => l.outboxTripCollection,
  OutboxKind.fuelFill => l.outboxFuelFill,
  _ => kind,
};
