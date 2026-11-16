import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/device_history_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _picker = ImagePicker();
  late Future<List<MediaHistoryEntry>> _historyFuture;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _historyFuture = DeviceHistoryService.getMediaHistory();
  }

  void _reload() {
    setState(() => _historyFuture = DeviceHistoryService.getMediaHistory());
  }

  Future<void> _pickPhotos() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final permission = await Permission.photos.request();
      if (!permission.isGranted && !permission.isLimited) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                permission.isPermanentlyDenied
                    ? 'Photo library access is blocked. Enable it in app settings.'
                    : 'Photo library permission is required to select images.',
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

      final selected = await _picker.pickMultiImage(imageQuality: 90);
      for (final image in selected) {
        await DeviceHistoryService.saveImage(image, source: 'gallery');
      }
      if (selected.isNotEmpty) _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select photos: $error')),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _remove(MediaHistoryEntry entry) async {
    await DeviceHistoryService.removeImage(entry);
    if (mounted) _reload();
  }

  Widget _thumbnail(MediaHistoryEntry entry) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: 72,
      height: 72,
      child: File(entry.path).existsSync()
          ? Image.file(File(entry.path), fit: BoxFit.cover)
          : const ColoredBox(
              color: Color(0xFFE5E7EB),
              child: Icon(Icons.broken_image_outlined),
            ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gallery')),
    body: FutureBuilder<List<MediaHistoryEntry>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        final history = snapshot.data ?? const <MediaHistoryEntry>[];
        final gallery = history
            .where((entry) => entry.source == 'gallery')
            .toList();
        final recent = gallery.take(3).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: _picking ? null : _pickPhotos,
              icon: _picking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: Text(_picking ? 'Opening gallery…' : 'Select Photos'),
            ),
            const SizedBox(height: 16),
            Text(
              'Last three selected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              const Text('Selected images will appear here.')
            else
              Row(
                children: [
                  for (final entry in recent) ...[
                    _thumbnail(entry),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            Text(
              'Selected image history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (gallery.isEmpty)
              const Text('No gallery images have been selected yet.')
            else
              for (final entry in gallery)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        _thumbnail(entry),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text('Size · ${_formatSize(entry.sizeBytes)}'),
                              Text(
                                'Selected · ${entry.capturedAt.toLocal()}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove image',
                          onPressed: () => _remove(entry),
                          icon: const Icon(Icons.delete_outline),
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    ),
  );
}
