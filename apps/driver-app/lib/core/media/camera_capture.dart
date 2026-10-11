import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/app_localizations.dart';
import '../location/gps.dart';
import 'captured_photo.dart';
import 'photo_store.dart';
import 'photo_store_platform.dart';

/// Opens the capture flow and returns the photo, or null if the driver backed out.
/// Swappable (via a provider) so widget tests don't need a real camera.
typedef PhotoCapture =
    Future<CapturedPhoto?> Function(BuildContext context, String kind);

/// Production capture: the in-app camera only. There's deliberately no gallery
/// option, so evidence is always a fresh photo with its own time and place.
/// The photo is kept in [store] until it's uploaded.
Future<CapturedPhoto?> captureWithCamera(
  BuildContext context,
  String kind,
  PhotoStore store,
) => Navigator.of(context).push<CapturedPhoto>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => CameraCaptureScreen(kind: kind, store: store),
  ),
);

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({
    required this.kind,
    required this.store,
    super.key,
  });

  /// odometer, fuel_receipt or document.
  final String kind;
  final PhotoStore store;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(
            context,
          ).cameraUnavailable(error: '$error'),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    setState(() => _busy = true);
    try {
      final capturedAt = DateTime.now().toUtc();
      final file = await controller.takePicture();
      final position = await currentPosition();
      final id = const Uuid().v4();
      final bytes = await file.readAsBytes();
      final path = await widget.store.save(id, bytes);
      await discardCameraFile(file.path);
      if (!mounted) return;
      Navigator.of(context).pop(
        CapturedPhoto(
          id: id,
          kind: widget.kind,
          path: path,
          sha256: sha256Of(bytes),
          byteSize: bytes.length,
          capturedAt: capturedAt,
          lat: position?.latitude,
          lng: position?.longitude,
          accuracyM: position?.accuracy,
          isMock: position?.isMocked ?? false,
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(
            context,
          ).couldNotTakePhoto(error: '$error'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final l = AppLocalizations.of(context);
    final (title, hint) = switch (widget.kind) {
      'odometer' => (l.odometerPhoto, l.fitOdometer),
      'document' => (l.documentPhoto, l.fitDocument),
      _ => (l.receiptPhoto, l.fitReceipt),
    };
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(title)),
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            )
          : controller == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: Center(child: CameraPreview(controller))),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    hint,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: controller == null
          ? null
          : FloatingActionButton.large(
              onPressed: _busy ? null : _capture,
              child: _busy
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.camera_alt),
            ),
    );
  }
}
