import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/device_history_service.dart';
import 'camera_screen.dart';
import 'gallery_screen.dart';
import 'sensor_screens.dart';

class DeviceDashboardScreen extends StatefulWidget {
  const DeviceDashboardScreen({super.key});

  @override
  State<DeviceDashboardScreen> createState() => _DeviceDashboardScreenState();
}

class _DeviceDashboardScreenState extends State<DeviceDashboardScreen> {
  late Future<MediaHistoryEntry?> _latestImage;

  @override
  void initState() {
    super.initState();
    _latestImage = _loadLatestImage();
  }

  Future<MediaHistoryEntry?> _loadLatestImage() async {
    final entries = await DeviceHistoryService.getMediaHistory();
    return entries.isEmpty ? null : entries.first;
  }

  Future<void> _open(Widget page) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (mounted) setState(() => _latestImage = _loadLatestImage());
  }

  String _axisValue(double? value) =>
      value == null ? '—' : value.toStringAsFixed(2);

  Widget _status(String label, bool active) => Chip(
    avatar: Icon(
      active ? Icons.check_circle : Icons.hourglass_top,
      size: 16,
      color: active ? const Color(0xFF2E7D32) : Colors.orange,
    ),
    label: Text('$label: ${active ? 'Active' : 'Waiting'}'),
    side: BorderSide.none,
    backgroundColor: active ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
  );

  Widget _sensorVectorCard({
    required String title,
    required IconData icon,
    required double? x,
    required double? y,
    required double? z,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF800000)),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'X  ${_axisValue(x)}     Y  ${_axisValue(y)}     Z  ${_axisValue(z)}',
          ),
        ],
      ),
    ),
  );

  Widget _sectionNavigation(String label, Widget page, IconData icon) =>
      OutlinedButton.icon(
        onPressed: () => _open(page),
        icon: Icon(icon),
        label: Text(label),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Device Monitoring')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 0,
          children: [
            _status('Camera', true),
            StreamBuilder<UserAccelerometerEvent>(
              stream: userAccelerometerEventStream(),
              builder: (context, snapshot) =>
                  _status('Accelerometer', snapshot.hasData),
            ),
            StreamBuilder<GyroscopeEvent>(
              stream: gyroscopeEventStream(),
              builder: (context, snapshot) =>
                  _status('Gyroscope', snapshot.hasData),
            ),
            StreamBuilder<MagnetometerEvent>(
              stream: magnetometerEventStream(),
              builder: (context, snapshot) =>
                  _status('Compass', snapshot.hasData),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _open(const CameraScreen()),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _open(const GalleryScreen()),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Select Photo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Image',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FutureBuilder<MediaHistoryEntry?>(
                  future: _latestImage,
                  builder: (context, snapshot) {
                    final entry = snapshot.data;
                    if (entry == null || !File(entry.path).existsSync()) {
                      return Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.image_outlined, size: 40),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(entry.path),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${entry.name} · ${entry.capturedAt.toLocal()}'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<UserAccelerometerEvent>(
          stream: userAccelerometerEventStream(),
          builder: (context, snapshot) => _sensorVectorCard(
            title: 'Movement Data (X, Y, Z)',
            icon: Icons.sensors_outlined,
            x: snapshot.data?.x,
            y: snapshot.data?.y,
            z: snapshot.data?.z,
          ),
        ),
        StreamBuilder<GyroscopeEvent>(
          stream: gyroscopeEventStream(),
          builder: (context, snapshot) => _sensorVectorCard(
            title: 'Gyroscope (X, Y, Z)',
            icon: Icons.rotate_90_degrees_ccw_outlined,
            x: snapshot.data?.x,
            y: snapshot.data?.y,
            z: snapshot.data?.z,
          ),
        ),
        StreamBuilder<MagnetometerEvent>(
          stream: magnetometerEventStream(),
          builder: (context, snapshot) {
            final event = snapshot.data;
            final heading = event == null
                ? null
                : (math.atan2(event.y, event.x) * 180 / math.pi + 360) % 360;
            const points = ['N', 'E', 'S', 'W'];
            final direction = heading == null
                ? '—'
                : points[((heading + 45) / 90).floor() % 4];
            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.explore_outlined,
                  color: Color(0xFF800000),
                ),
                title: const Text('Compass Direction'),
                subtitle: Text(
                  heading == null
                      ? 'Waiting for magnetometer…'
                      : '$direction · ${heading.toStringAsFixed(0)}°',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Sensor dashboards',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _sectionNavigation(
              'Accelerometer',
              const AccelerometerScreen(),
              Icons.sensors_outlined,
            ),
            _sectionNavigation(
              'Gyroscope',
              const GyroscopeScreen(),
              Icons.rotate_90_degrees_ccw_outlined,
            ),
            _sectionNavigation(
              'Compass',
              const CompassScreen(),
              Icons.explore_outlined,
            ),
          ],
        ),
      ],
    ),
  );
}
