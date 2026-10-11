import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/owner_models.dart';
import '../../core/media/captured_photo.dart';
import '../../core/media/upload_now.dart';
import '../common/format.dart';
import '../common/widgets.dart';
import 'owner_providers.dart';
import 'owner_text.dart';
import 'owner_widgets.dart';

const _windows = <int?>[null, 30, 7, 0];

/// Every current document, optionally only those due soon.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  int? _within;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final query = (
      vehicleId: null,
      driverId: null,
      expiringWithinDays: _within,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.documents)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-document'),
        icon: const Icon(Icons.add),
        label: Text(l.addDocument),
        onPressed: () => openScreen<void>(context, const DocumentFormScreen()),
      ),
      body: RefreshPage(
        onRefresh: () => ref.refresh(documentsProvider(query).future),
        children: [
          SizedBox(
            width: 280,
            child: DropdownButtonFormField<int?>(
              initialValue: _within,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.status, isDense: true),
              items: [
                for (final w in _windows)
                  DropdownMenuItem<int?>(
                    value: w,
                    child: Text(switch (w) {
                      30 => l.filterDue30,
                      7 => l.filterDue7,
                      0 => l.filterDue0,
                      _ => l.filterAllDocs,
                    }),
                  ),
              ],
              onChanged: (v) => setState(() => _within = v),
            ),
          ),
          const SizedBox(height: 8),
          DocumentsList(query: query),
        ],
      ),
    );
  }
}

/// Documents matching [query], each with view and renew. Shows whose document
/// it is unless the list is already for one vehicle or driver.
class DocumentsList extends ConsumerWidget {
  const DocumentsList({required this.query, super.key});
  final DocumentQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = context.fmt;
    final docs = ref.watch(documentsProvider(query));
    final vehicles = ref.watch(fleetVehiclesProvider).value ?? const [];
    final drivers = ref.watch(driversProvider).value ?? const [];
    final scoped = query.vehicleId != null || query.driverId != null;
    String subject(FleetDocument d) {
      if (d.vehicleId != null) {
        final v = vehicles.where((v) => v.id == d.vehicleId).firstOrNull;
        return v == null ? l.noValue : formatRegistration(v.registrationNo);
      }
      return drivers.where((x) => x.id == d.driverId).firstOrNull?.name ??
          l.noValue;
    }

    return AsyncView(
      value: docs,
      onRetry: () => ref.invalidate(documentsProvider(query)),
      builder: (list) => list.isEmpty
          ? EmptyState(l.noDocuments)
          : Column(
              children: [
                for (final d in list)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      key: ValueKey('document-${d.id}'),
                      title: Text(
                        scoped
                            ? docTypeLabel(l, d.docType)
                            : '${docTypeLabel(l, d.docType)} · ${subject(d)}',
                      ),
                      subtitle: Text(
                        [
                          ?d.number,
                          '${l.expiresOn}: ${fmt.calendarDate(d.expiresOn)}',
                        ].join(' · '),
                      ),
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          DocumentStatusChip(d),
                          PopupMenuButton<String>(
                            onSelected: (action) => switch (action) {
                              'view' => _view(context, d),
                              _ => openScreen<void>(
                                context,
                                DocumentFormScreen(renewing: d),
                              ),
                            },
                            itemBuilder: (_) => [
                              if (d.mediaId != null)
                                PopupMenuItem(
                                  value: 'view',
                                  child: Text(l.viewPhoto),
                                ),
                              if (d.status != 'superseded')
                                PopupMenuItem(
                                  value: 'renew',
                                  child: Text(l.renew),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _view(BuildContext context, FleetDocument d) => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(docTypeLabel(dialog.l10n, d.docType)),
      content: SizedBox(width: 480, child: MediaPhoto(d.mediaId!, height: 420)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text(dialog.l10n.close),
        ),
      ],
    ),
  );
}

class DocumentStatusChip extends StatelessWidget {
  const DocumentStatusChip(this.doc, {super.key});
  final FleetDocument doc;

  @override
  Widget build(BuildContext context) => ToneChip(
    documentStatusText(context.l10n, doc),
    tone: switch (doc.status) {
      'expired' => Tone.danger,
      'expiring' => doc.daysLeft <= 7 ? Tone.danger : Tone.warning,
      'superseded' => Tone.neutral,
      _ => Tone.success,
    },
  );
}

/// Adds a document (for [vehicleId] or [driverId] when given) or renews [renewing].
/// The optional photo is uploaded straight away through the media flow.
class DocumentFormScreen extends ConsumerStatefulWidget {
  const DocumentFormScreen({
    this.renewing,
    this.vehicleId,
    this.driverId,
    super.key,
  });

  final FleetDocument? renewing;
  final String? vehicleId;
  final String? driverId;

  @override
  ConsumerState<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends ConsumerState<DocumentFormScreen> {
  late final _number = TextEditingController(
    text: widget.renewing?.number ?? '',
  );
  late String _docType =
      widget.renewing?.docType ??
      (widget.driverId != null ? 'driving_licence' : 'insurance');
  late String? _vehicleId = widget.vehicleId;
  late String? _driverId = widget.driverId;
  String? _validFrom;
  String? _expiresOn;
  CapturedPhoto? _photo;
  String? _problem;
  bool _busy = false;

  bool get _forDriver => _docType == 'driving_licence';

  List<String> get _types => widget.vehicleId != null
      ? FleetDocument.vehicleTypes
      : widget.driverId != null
      ? FleetDocument.driverTypes
      : [...FleetDocument.vehicleTypes, ...FleetDocument.driverTypes];

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final renewing = widget.renewing;
    final subjectMissing =
        renewing == null &&
        (_forDriver ? _driverId == null : _vehicleId == null);
    if (_expiresOn == null || subjectMissing) {
      setState(
        () => _problem = subjectMissing ? l.pickVehicleOrDriver : l.required,
      );
      return;
    }
    setState(() {
      _problem = null;
      _busy = true;
    });
    final navigator = Navigator.of(context);
    final ok = await runAction(context, () async {
      String? mediaId;
      final photo = _photo;
      if (photo != null) {
        mediaId = await uploadPhotoNow(
          ref.read(apiProvider),
          photo,
          readBytes: ref.read(photoStoreProvider).read,
          deviceId: await ref.read(sessionStoreProvider).deviceId(),
        );
      }
      final details = {
        'expiresOn': _expiresOn,
        if (_number.text.trim().isNotEmpty) 'number': _number.text.trim(),
        'validFrom': ?_validFrom,
        'mediaId': ?mediaId,
      };
      final api = ref.read(ownerApiProvider);
      if (renewing != null) {
        await api.renewDocument(renewing.id, details);
      } else {
        await api.createDocument({
          ...details,
          'docType': _docType,
          if (_forDriver) 'driverId': _driverId else 'vehicleId': _vehicleId,
        });
      }
      refreshAfter(ref, {OwnerArea.documents, OwnerArea.alerts});
    });
    if (ok) {
      navigator.pop();
    } else if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final renewing = widget.renewing;
    final scoped = widget.vehicleId != null || widget.driverId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          renewing == null
              ? l.addDocument
              : l.renewTitle(doc: docTypeLabel(l, renewing.docType)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (renewing != null)
                  Text(l.renewIntro)
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _docType,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.documentType),
                    items: [
                      for (final t in _types)
                        DropdownMenuItem(
                          value: t,
                          child: Text(docTypeLabel(l, t)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _docType = v ?? _docType),
                  ),
                  if (!scoped) ...[
                    const SizedBox(height: 12),
                    if (_forDriver)
                      DriverPicker(
                        value: _driverId,
                        label: l.documentFor,
                        onChanged: (v) => setState(() => _driverId = v),
                      )
                    else
                      VehiclePicker(
                        value: _vehicleId,
                        label: l.documentFor,
                        activeOnly: false,
                        onChanged: (v) => setState(() => _vehicleId = v),
                      ),
                  ],
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _number,
                  decoration: InputDecoration(labelText: l.documentNumber),
                ),
                const SizedBox(height: 12),
                _DatePickField(
                  label: l.validFrom,
                  value: _validFrom == null
                      ? l.optional
                      : fmt.calendarDate(_validFrom!),
                  onTap: () async {
                    final d = await pickIsoDate(context, value: _validFrom);
                    if (d != null) setState(() => _validFrom = d);
                  },
                ),
                const SizedBox(height: 12),
                _DatePickField(
                  key: const Key('document-expires'),
                  label: l.expiresOn,
                  hint: l.expiresOnHint,
                  value: _expiresOn == null
                      ? l.pickDate
                      : fmt.calendarDate(_expiresOn!),
                  onTap: () async {
                    final d = await pickIsoDate(context, value: _expiresOn);
                    if (d != null) setState(() => _expiresOn = d);
                  },
                ),
                const SizedBox(height: 12),
                PhotoField(
                  kind: 'document',
                  label: l.documentPhotoOptional,
                  photo: _photo,
                  onChanged: (p) => setState(() => _photo = p),
                ),
                if (_problem != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _problem!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('document-save'),
                  onPressed: _busy ? null : _save,
                  child: Text(renewing == null ? l.addDocument : l.saveRenewal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickField extends StatelessWidget {
  const _DatePickField({
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    super.key,
  });

  final String label;
  final String value;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
      child: Text(value),
    ),
  );
}
