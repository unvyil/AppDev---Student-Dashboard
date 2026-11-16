import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/device_history_service.dart';

enum _SensorKind { accelerometer, gyroscope, compass }

class AccelerometerScreen extends StatelessWidget {
  const AccelerometerScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _SensorMonitorScreen(kind: _SensorKind.accelerometer);
}

class GyroscopeScreen extends StatelessWidget {
  const GyroscopeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _SensorMonitorScreen(kind: _SensorKind.gyroscope);
}

class CompassScreen extends StatelessWidget {
  const CompassScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _SensorMonitorScreen(kind: _SensorKind.compass);
}

class _AxisSample {
  const _AxisSample(this.x, this.y, this.z, this.timestamp);

  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
}

class _SensorMonitorScreen extends StatefulWidget {
  const _SensorMonitorScreen({required this.kind});

  final _SensorKind kind;

  @override
  State<_SensorMonitorScreen> createState() => _SensorMonitorScreenState();
}

class _SensorMonitorScreenState extends State<_SensorMonitorScreen> {
  StreamSubscription<_AxisSample>? _subscription;
  _AxisSample? _current;
  _AxisSample? _previous;
  _AxisSample? _peak;
  final List<SensorHistoryEntry> _history = [];
  final Map<String, int> _directionCounts = {'N': 0, 'E': 0, 'S': 0, 'W': 0};
  DateTime? _lastPersisted;
  String? _direction;
  double? _heading;
  String? _error;

  String get _sensorKey => switch (widget.kind) {
    _SensorKind.accelerometer => 'accelerometer',
    _SensorKind.gyroscope => 'gyroscope',
    _SensorKind.compass => 'compass',
  };

  String get _title => switch (widget.kind) {
    _SensorKind.accelerometer => 'Accelerometer',
    _SensorKind.gyroscope => 'Gyroscope',
    _SensorKind.compass => 'Magnetometer & Compass',
  };

  Stream<_AxisSample> _sensorStream() {
    const period = SensorInterval.normalInterval;
    return switch (widget.kind) {
      _SensorKind.accelerometer => userAccelerometerEventStream(
        samplingPeriod: period,
      ).map((event) => _AxisSample(event.x, event.y, event.z, DateTime.now())),
      _SensorKind.gyroscope => gyroscopeEventStream(
        samplingPeriod: period,
      ).map((event) => _AxisSample(event.x, event.y, event.z, DateTime.now())),
      _SensorKind.compass => magnetometerEventStream(
        samplingPeriod: period,
      ).map((event) => _AxisSample(event.x, event.y, event.z, DateTime.now())),
    };
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
    _subscription = _sensorStream().listen(
      _onSample,
      onError: (Object error) {
        if (mounted) setState(() => _error = 'Sensor unavailable: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final entries = await DeviceHistoryService.getSensorHistory(_sensorKey);
    if (!mounted) return;
    setState(() {
      _history
        ..clear()
        ..addAll(entries.reversed.take(12));
      if (widget.kind == _SensorKind.compass) {
        for (final entry in entries) {
          final direction = entry.direction;
          if (direction != null && _directionCounts.containsKey(direction)) {
            _directionCounts[direction] = _directionCounts[direction]! + 1;
          }
        }
      }
    });
  }

  void _onSample(_AxisSample sample) {
    final heading = widget.kind == _SensorKind.compass
        ? (math.atan2(sample.y, sample.x) * 180 / math.pi + 360) % 360
        : null;
    final direction = heading == null ? null : _directionFor(heading);
    setState(() {
      _previous = _current;
      _current = sample;
      if (_peak == null ||
          sample.x.abs() > _peak!.x.abs() ||
          sample.y.abs() > _peak!.y.abs() ||
          sample.z.abs() > _peak!.z.abs()) {
        _peak = _AxisSample(
          math.max(_peak?.x.abs() ?? 0, sample.x.abs()),
          math.max(_peak?.y.abs() ?? 0, sample.y.abs()),
          math.max(_peak?.z.abs() ?? 0, sample.z.abs()),
          sample.timestamp,
        );
      }
      if (heading != null && direction != null && direction != _direction) {
        _direction = direction;
        _directionCounts[direction] = (_directionCounts[direction] ?? 0) + 1;
      }
      _heading = heading;
      _error = null;
    });

    final last = _lastPersisted;
    if (last == null || sample.timestamp.difference(last).inSeconds >= 1) {
      _lastPersisted = sample.timestamp;
      final record = SensorHistoryEntry(
        sensor: _sensorKey,
        x: sample.x,
        y: sample.y,
        z: sample.z,
        timestamp: sample.timestamp,
        direction: direction,
      );
      unawaited(DeviceHistoryService.recordSensor(record));
      setState(() {
        _history.insert(0, record);
        if (_history.length > 12) _history.removeLast();
      });
    }
  }

  String? _directionFor(double heading) {
    if (heading >= 315 || heading < 45) return 'N';
    if (heading < 135) return 'E';
    if (heading < 225) return 'S';
    return 'W';
  }

  String _value(double? value) =>
      value == null ? '—' : value.toStringAsFixed(2);

  Widget _axesCard(String title, _AxisSample? sample, IconData icon) => Card(
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _axisValue('X', _value(sample?.x)),
              _axisValue('Y', _value(sample?.y)),
              _axisValue('Z', _value(sample?.z)),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _axisValue(String axis, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(axis, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_title)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _current == null ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _current == null ? 'Waiting for sensor' : 'Live updates active',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            if (_current != null)
              Text(
                '${_current!.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${_current!.timestamp.toLocal().minute.toString().padLeft(2, '0')}:${_current!.timestamp.toLocal().second.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 10),
        _axesCard('Current X, Y, Z', _current, Icons.sensors_outlined),
        _axesCard('Peak absolute values', _peak, Icons.show_chart),
        if (widget.kind == _SensorKind.gyroscope)
          _axesCard('Previous values', _previous, Icons.history),
        if (widget.kind == _SensorKind.compass) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.explore_outlined,
                    size: 38,
                    color: Color(0xFF800000),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _direction == null
                        ? '—'
                        : '$_direction · ${_heading!.toStringAsFixed(0)}°',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Text('Cardinal heading'),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 20,
                children: [
                  for (final direction in const ['N', 'E', 'S', 'W'])
                    Text('$direction · ${_directionCounts[direction]}'),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          widget.kind == _SensorKind.compass
              ? 'Direction history'
              : widget.kind == _SensorKind.gyroscope
              ? 'Rotational movement logs'
              : 'Movement history',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        if (_history.isEmpty)
          const Text('Sensor readings will be saved here as they arrive.')
        else
          for (final entry in _history)
            ListTile(
              dense: true,
              leading: Icon(
                widget.kind == _SensorKind.compass
                    ? Icons.explore_outlined
                    : Icons.sensors_outlined,
              ),
              title: Text(
                widget.kind == _SensorKind.compass && entry.direction != null
                    ? 'Direction ${entry.direction}'
                    : 'X ${entry.x.toStringAsFixed(2)} · Y ${entry.y.toStringAsFixed(2)} · Z ${entry.z.toStringAsFixed(2)}',
              ),
              subtitle: Text(entry.timestamp.toLocal().toString()),
            ),
      ],
    ),
  );
}
