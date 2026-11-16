import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/device_history_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  MediaHistoryEntry? _latest;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    final entries = await DeviceHistoryService.getMediaHistory();
    if (!mounted) return;
    setState(() {
      _latest = entries.where((entry) => entry.source == 'camera').firstOrNull;
    });
  }

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                permission.isPermanentlyDenied
                    ? 'Camera access is blocked. Enable it in app settings.'
                    : 'Camera permission is required to take a photo.',
              ),
              action: permission.isPermanentlyDenied
                  ? SnackBarAction(
                      label: 'Settings',
                      onPressed: openAppSettings,
                    )
                  : null,
            ),
          );
        }
        return;
      }

      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image == null) return;
      final saved = await DeviceHistoryService.saveImage(
        image,
        source: 'camera',
      );
      if (!mounted) return;
      setState(() => _latest = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo saved at ${saved.capturedAt}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture photo: $error')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Camera')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest captured image',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (_latest != null && File(_latest!.path).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_latest!.path),
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 210,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.photo_camera_outlined, size: 48),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  _latest == null
                      ? 'No photo captured yet.'
                      : 'Captured · ${_latest!.capturedAt.toLocal()}',
                ),
                if (_latest != null)
                  Text(
                    'Saved privately · ${_latest!.path}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _capturing ? null : _capture,
          icon: _capturing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt_outlined),
          label: Text(_capturing ? 'Opening camera…' : 'Take Photo'),
        ),
        const SizedBox(height: 6),
        Text(
          'Take another photo at any time. Each capture is added to the private dashboard image history.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
