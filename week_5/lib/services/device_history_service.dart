import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class MediaHistoryEntry {
  const MediaHistoryEntry({
    required this.path,
    required this.name,
    required this.source,
    required this.capturedAt,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final String source;
  final DateTime capturedAt;
  final int sizeBytes;

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'source': source,
    'capturedAt': capturedAt.toIso8601String(),
    'sizeBytes': sizeBytes,
  };

  factory MediaHistoryEntry.fromJson(Map<String, dynamic> json) =>
      MediaHistoryEntry(
        path: json['path'] as String? ?? '',
        name: json['name'] as String? ?? 'image',
        source: json['source'] as String? ?? 'gallery',
        capturedAt:
            DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
            DateTime.now(),
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      );
}

class SensorHistoryEntry {
  const SensorHistoryEntry({
    required this.sensor,
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
    this.direction,
  });

  final String sensor;
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
  final String? direction;

  Map<String, dynamic> toJson() => {
    'sensor': sensor,
    'x': x,
    'y': y,
    'z': z,
    'timestamp': timestamp.toIso8601String(),
    'direction': direction,
  };

  factory SensorHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SensorHistoryEntry(
        sensor: json['sensor'] as String? ?? 'sensor',
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        z: (json['z'] as num?)?.toDouble() ?? 0,
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        direction: json['direction'] as String?,
      );
}

class DeviceHistoryService {
  static const _mediaKey = 'week5_device_media_history';
  static const _sensorKeyPrefix = 'week5_sensor_history_';

  static Future<MediaHistoryEntry> saveImage(
    XFile image, {
    required String source,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/device_media');
    await directory.create(recursive: true);
    final capturedAt = DateTime.now();
    final extension = image.name.contains('.')
        ? image.name.substring(image.name.lastIndexOf('.'))
        : '.jpg';
    final name = 'image_${capturedAt.microsecondsSinceEpoch}$extension';
    final file = await File(image.path).copy('${directory.path}/$name');
    final entry = MediaHistoryEntry(
      path: file.path,
      name: name,
      source: source,
      capturedAt: capturedAt,
      sizeBytes: await file.length(),
    );
    final entries = await getMediaHistory();
    entries.add(entry);
    await _saveMediaHistory(entries);
    return entry;
  }

  static Future<List<MediaHistoryEntry>> getMediaHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mediaKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                MediaHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((entry) => File(entry.path).existsSync())
          .toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    } on FormatException {
      return [];
    }
  }

  static Future<void> removeImage(MediaHistoryEntry entry) async {
    final file = File(entry.path);
    if (await file.exists()) await file.delete();
    final entries = await getMediaHistory()
      ..removeWhere((item) => item.path == entry.path);
    await _saveMediaHistory(entries);
  }

  static Future<void> _saveMediaHistory(List<MediaHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mediaKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  static Future<void> recordSensor(SensorHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_sensorKeyPrefix${entry.sensor}';
    final entries = await getSensorHistory(entry.sensor);
    entries.add(entry);
    final recent = entries.length > 100
        ? entries.sublist(entries.length - 100)
        : entries;
    await prefs.setString(
      key,
      jsonEncode(recent.map((item) => item.toJson()).toList()),
    );
  }

  static Future<List<SensorHistoryEntry>> getSensorHistory(
    String sensor,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_sensorKeyPrefix$sensor');
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                SensorHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on FormatException {
      return [];
    }
  }
}
