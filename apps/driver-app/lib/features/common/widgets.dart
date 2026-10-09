import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/media/captured_photo.dart';
import '../../core/sync/sync_engine.dart';
import 'format.dart';

/// 🟢 Synced / 🟡 N pending / 🔴 Offline, plus a tap-through for items that need attention.
class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  static String label(SyncStatus s) {
    if (!s.online) {
      return s.pending == 0
          ? 'Offline'
          : 'Offline · ${s.pending} saved on phone';
    }
    if (s.pending > 0) return '${s.pending} pending';
    return 'Synced';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider).value;
    if (status == null) return const SizedBox.shrink();
    final (Color color, IconData icon) = !status.online
        ? (Colors.red.shade700, Icons.cloud_off)
        : status.pending > 0
        ? (Colors.amber.shade800, Icons.cloud_upload)
        : (Colors.green.shade700, Icons.cloud_done);
    return Material(
      color: color.withValues(alpha: 0.12),
      child: InkWell(
        onTap: status.attention > 0 ? () => _showAttention(context, ref) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color, semanticLabel: 'Sync status'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label(status),
                  key: const Key('sync-status-label'),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              if (status.attention > 0)
                Text(
                  '${status.attention} need attention',
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
            const ListTile(
              title: Text('These could not be sent'),
              subtitle: Text(
                'The server rejected them. Ask your owner, or retry.',
              ),
            ),
            for (final item in items)
              ListTile(
                dense: true,
                leading: const Icon(Icons.error_outline),
                title: Text(item.kind),
                subtitle: Text(item.lastError ?? ''),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () async {
                  await engine.outbox.retryAttention();
                  unawaited(engine.syncNow());
                  if (sheet.mounted) Navigator.of(sheet).pop();
                },
                child: const Text('Retry all'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notice.message),
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
      label: Text(statusLabels[status] ?? status),
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
    final file = current == null ? null : File(current.path);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          if (file != null && file.existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(file, width: 64, height: 48, fit: BoxFit.cover),
            )
          else
            Icon(
              current == null
                  ? Icons.photo_camera_outlined
                  : Icons.check_circle,
              color: current == null ? null : Colors.green,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(current == null ? 'No photo yet' : 'Photo taken'),
          ),
          TextButton.icon(
            onPressed: () async {
              final taken = await ref.read(photoCaptureProvider)(context, kind);
              if (taken != null) onChanged(taken);
            },
            icon: const Icon(Icons.camera_alt),
            label: Text(current == null ? 'Take photo' : 'Retake'),
          ),
        ],
      ),
    );
  }
}

/// Validates whole kilometres.
String? validateKm(String? value, {int? atLeast}) {
  final km = int.tryParse((value ?? '').trim());
  if (km == null || km < 0) return 'Enter the odometer reading in km';
  if (atLeast != null && km < atLeast) return 'Must be at least $atLeast km';
  return null;
}

String? validateRupees(String? value, {bool allowZero = false}) {
  final paise = parseRupees(value ?? '');
  if (paise == null) return 'Enter an amount in ₹';
  if (!allowZero && paise == 0) return 'Amount must be more than ₹0';
  return null;
}
