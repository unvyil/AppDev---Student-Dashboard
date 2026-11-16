import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

/// Shared JSONPlaceholder source used by the student and faculty directories.
class PortalDataService {
  static const _usersCacheKey = 'jsonplaceholder_users_cache';
  static Future<List<Map<String, dynamic>>>? _inFlightUsersRequest;

  // JSONPlaceholder-compatible offline snapshot for first launch without a
  // connection. Successful API responses replace this with a full cache.
  static const List<Map<String, dynamic>> _offlineUsers = [
    {
      'id': 1,
      'name': 'Leanne Graham',
      'email': 'Sincere@april.biz',
      'phone': '1-770-736-8031 x56442',
      'address': {'city': 'Gwenborough'},
      'company': {'name': 'Romaguera-Crona'},
    },
    {
      'id': 2,
      'name': 'Ervin Howell',
      'email': 'Shanna@melissa.tv',
      'phone': '010-692-6593 x09125',
      'address': {'city': 'Wisokyburgh'},
      'company': {'name': 'Deckow-Crist'},
    },
    {
      'id': 3,
      'name': 'Clementine Bauch',
      'email': 'Nathan@yesenia.net',
      'phone': '1-463-123-4447',
      'address': {'city': 'McKenziehaven'},
      'company': {'name': 'Romaguera-Jacobson'},
    },
    {
      'id': 4,
      'name': 'Patricia Lebsack',
      'email': 'Julianne.OConner@kory.org',
      'phone': '493-170-9623 x156',
      'address': {'city': 'South Elvis'},
      'company': {'name': 'Robel-Corkery'},
    },
  ];

  static List<Map<String, dynamic>> get mockUsers =>
      _offlineUsers.map((user) => Map<String, dynamic>.from(user)).toList();

  static Future<List<Map<String, dynamic>>> fetchUsers() {
    final currentRequest = _inFlightUsersRequest;
    if (currentRequest != null) return currentRequest;

    final request = _loadUsers();
    _inFlightUsersRequest = request;
    return request.whenComplete(() {
      if (identical(_inFlightUsersRequest, request)) {
        _inFlightUsersRequest = null;
      }
    });
  }

  /// Allows a fresh read from the cache as soon as connectivity changes, even
  /// if a request that started while online is still waiting on a timeout.
  static void resetInFlightRequest() {
    _inFlightUsersRequest = null;
  }

  static Future<List<Map<String, dynamic>>> _loadUsers() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasNetwork = connectivity.any(
        (result) => result != ConnectivityResult.none,
      );
      if (!hasNetwork) return await _getCachedOrBundledUsers();

      final response = await http
          .get(
            Uri.https('jsonplaceholder.typicode.com', '/users'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception(
          'JSONPlaceholder returned HTTP ${response.statusCode}.',
        );
      }
      final users = _decodeUsers(response.body);
      if (users.isEmpty) {
        throw const FormatException('JSONPlaceholder returned no users.');
      }
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(_usersCacheKey, jsonEncode(users));
      } catch (_) {
        // Keep the live response if local caching is unavailable.
      }
      return users;
    } catch (_) {
      return _getCachedOrBundledUsers();
    }
  }

  static Future<List<Map<String, dynamic>>> _getCachedOrBundledUsers() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final cached = preferences.getString(_usersCacheKey);
      if (cached != null) {
        final users = _decodeUsers(cached);
        if (users.isNotEmpty) return users;
      }
    } catch (_) {
      // Use the bundled snapshot if preferences are unavailable.
    }
    return _offlineUsers
        .map((user) => Map<String, dynamic>.from(user))
        .toList();
  }

  static List<Map<String, dynamic>> _decodeUsers(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const FormatException('JSONPlaceholder users response is invalid.');
    }
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Student toStudent(Map<String, dynamic> user, int index) {
    final id = (user['id'] as num?)?.toInt() ?? index + 1;
    final address = user['address'] is Map
        ? Map<String, dynamic>.from(user['address'] as Map)
        : <String, dynamic>{};
    const programs = ['BSIT-WM', 'BSIT-NS', 'BSCS-DS', 'BSCS-SE'];
    return Student(
      name: user['name'] as String? ?? 'Student $id',
      id: 'JP-${id.toString().padLeft(4, '0')}',
      email: user['email'] as String? ?? 'student$id@example.test',
      program: programs[(id - 1) % programs.length],
      yearLevel: '${(id - 1) % 4 + 1}${_ordinal((id - 1) % 4 + 1)} Year',
      contact: user['phone'] as String? ?? '',
      address: address['city'] as String? ?? '',
      attendance: 0.80 + ((id * 7) % 20) / 100,
    );
  }

  static String _ordinal(int number) {
    if (number == 1) return 'st';
    if (number == 2) return 'nd';
    if (number == 3) return 'rd';
    return 'th';
  }
}
