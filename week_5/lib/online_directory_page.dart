import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'services/portal_data_service.dart';
import 'theme/app_theme.dart';

class OnlineDirectoryPage extends StatefulWidget {
  const OnlineDirectoryPage({super.key, this.useMockData = false});

  final bool useMockData;

  @override
  State<OnlineDirectoryPage> createState() => _OnlineDirectoryPageState();
}

class _OnlineDirectoryPageState extends State<OnlineDirectoryPage> {
  static const _cacheKey = 'week5_online_directory_cache';
  static const _updatedKey = 'week5_online_directory_updated';

  Timer? _timer;
  List<Map<String, dynamic>> _users = const [];
  DateTime? _lastUpdated;
  String _syncStatus = 'Syncing';
  bool _online = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _restoreCache();
    _sync();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _sync());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OnlineDirectoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useMockData != widget.useMockData) _sync();
  }

  Future<void> _restoreCache() async {
    if (widget.useMockData) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUsers = prefs.getString(_cacheKey);
      final updated = prefs.getString(_updatedKey);
      if (rawUsers == null) return;
      final decoded = jsonDecode(rawUsers);
      if (decoded is! List) return;
      if (!mounted) return;
      setState(() {
        _users = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _lastUpdated = DateTime.tryParse(updated ?? '');
      });
    } catch (_) {
      // A corrupt cache is ignored; the next successful sync replaces it.
    }
  }

  Future<void> _sync() async {
    if (_syncing) return;
    if (mounted) setState(() => _syncing = true);
    if (widget.useMockData) {
      if (mounted) {
        setState(() {
          _users = PortalDataService.mockUsers;
          _lastUpdated = null;
          _online = false;
          _syncStatus = 'Mock Data';
          _syncing = false;
        });
      }
      return;
    }
    try {
      final connections = await Connectivity().checkConnectivity();
      final connected = connections.any(
        (result) => result != ConnectivityResult.none,
      );
      if (!connected) {
        if (mounted) {
          setState(() {
            _online = false;
            _syncStatus = 'Offline';
          });
        }
        await _restoreCache();
        return;
      }

      final response = await http
          .get(
            Uri.https('jsonplaceholder.typicode.com', '/users'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('API returned HTTP ${response.statusCode}.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Invalid API response.');
      }
      final users = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(users));
      await prefs.setString(_updatedKey, now.toIso8601String());
      if (!mounted) return;
      setState(() {
        _users = users;
        _lastUpdated = now;
        _online = true;
        _syncStatus = 'Sync Successful';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _online = false;
          _syncStatus = 'Sync Failed';
        });
      }
      await _restoreCache();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  String _formatUpdated(DateTime? value) {
    if (value == null) return 'No successful sync yet';
    final local = value.toLocal();
    final date = '${local.month}/${local.day}/${local.year}';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$date · $hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
  }

  Widget _statusBadge(String label, bool active, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: active ? color : Theme.of(context).dividerColor,
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? color : Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _syncStatusCard() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: AppTokens.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: _online
                    ? const Color(0xFF2E7D32)
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                _online ? 'Online' : _syncStatus,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_syncing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Last updated · ${_formatUpdated(_lastUpdated)}'),
          Text('Users retrieved · ${_users.length}'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _statusBadge(
                'Sync Successful',
                _syncStatus == 'Sync Successful',
                const Color(0xFF2E7D32),
              ),
              _statusBadge(
                'Sync Failed',
                _syncStatus == 'Sync Failed',
                const Color(0xFFC62828),
              ),
              _statusBadge(
                'Offline',
                _syncStatus == 'Offline',
                const Color(0xFF6B7280),
              ),
              _statusBadge(
                'Mock Data',
                _syncStatus == 'Mock Data',
                const Color(0xFF7B2CBF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final company = user['company'] is Map
        ? Map<String, dynamic>.from(user['company'] as Map)
        : <String, dynamic>{};
    final name = user['name'] as String? ?? 'Unknown user';
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: AppTokens.softCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTokens.maroonPrimary,
            child: Text(
              initials.isEmpty ? 'U' : initials,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleSmall),
                Text(user['email'] as String? ?? 'No email listed'),
                Text('Phone · ${user['phone'] ?? 'Not listed'}'),
                Text('Company · ${company['name'] ?? 'Not listed'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Online Directory')),
    body: Column(
      children: [
        _syncStatusCard(),
        Expanded(
          child: _users.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _syncing ? 'Loading online directory…' : 'No cached user records are available. Connect to sync.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) => _userCard(_users[index]),
                ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _syncing ? null : _sync,
      icon: const Icon(Icons.sync),
      label: const Text('Sync'),
    ),
  );
}
