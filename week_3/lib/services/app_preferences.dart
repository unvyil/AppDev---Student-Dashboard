import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  static const _darkModeKey = 'dark_mode';
  static const _mockDataKey = 'mock_data';
  static const _profilePhotoKey = 'profile_photo';
  static const _rememberMeKey = 'remember_me';
  static const _savedUserIdKey = 'saved_user_id';
  static const _savedPasswordKey = 'saved_password';
  static const _authAccountsKey = 'auth_accounts_v1';
  static const _activeSessionEmailKey = 'active_session_email';

  ThemeMode _themeMode = ThemeMode.light;
  bool _useMockData = false;
  bool _rememberMe = false;
  String _savedUserId = '';
  String _savedPassword = '';
  Map<String, dynamic> _authAccounts = {};
  String? _activeUserEmail;
  String? _activeUserName;
  String? _profilePhotoBase64;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get useMockData => _useMockData;
  bool get rememberMe => _rememberMe;
  String get savedUserId => _savedUserId;
  String get savedPassword => _savedPassword;
  bool get hasActiveSession => _activeUserEmail != null;
  String? get activeUserEmail => _activeUserEmail;
  String? get activeUserName => _activeUserName;
  String? get profilePhotoBase64 => _profilePhotoBase64;

  Uint8List? get profilePhotoBytes {
    final encoded = _profilePhotoBase64;
    if (encoded == null) return null;
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final isDark = preferences.getBool(_darkModeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _useMockData = preferences.getBool(_mockDataKey) ?? false;
    _rememberMe = preferences.getBool(_rememberMeKey) ?? false;
    _savedUserId = _rememberMe
        ? preferences.getString(_savedUserIdKey) ?? ''
        : '';
    _savedPassword = _rememberMe
        ? preferences.getString(_savedPasswordKey) ?? ''
        : '';
    final accountsJson = preferences.getString(_authAccountsKey);
    if (accountsJson != null) {
      try {
        final decoded = jsonDecode(accountsJson);
        if (decoded is Map) {
          _authAccounts = Map<String, dynamic>.from(decoded);
        }
      } on FormatException {
        _authAccounts = {};
      }
    }
    final sessionEmail = preferences.getString(_activeSessionEmailKey);
    final session = sessionEmail == null ? null : _authAccounts[sessionEmail];
    if (session is Map) {
      _activeUserEmail = sessionEmail;
      _activeUserName = session['name'] as String?;
    } else {
      await preferences.remove(_activeSessionEmailKey);
      _activeUserEmail = null;
      _activeUserName = null;
    }
    _profilePhotoBase64 = preferences.getString(_profilePhotoKey);
    notifyListeners();
  }

  Future<void> createLocalAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    if (cleanName.isEmpty) {
      throw const FormatException('Full name is required.');
    }
    if (!_isInstitutionalEmail(cleanEmail)) {
      throw const FormatException('Use your @lpunetwork.edu.ph email.');
    }
    if (password.length < 8) {
      throw const FormatException(
        'Password must contain at least 8 characters.',
      );
    }
    if (_authAccounts.containsKey(cleanEmail)) {
      throw StateError('An account with this email already exists.');
    }

    final random = Random.secure();
    final salt = List.generate(
      16,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    _authAccounts[cleanEmail] = {
      'name': cleanName,
      'salt': salt,
      'passwordHash': _passwordHash(salt, password),
    };
    await _persistAccountsAndSession(cleanEmail);
  }

  Future<void> authenticateLocalAccount({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!_isInstitutionalEmail(cleanEmail)) {
      throw const FormatException('Use your @lpunetwork.edu.ph email.');
    }
    if (password.isEmpty) throw const FormatException('Password is required.');
    final account = _authAccounts[cleanEmail];
    if (account is! Map) {
      throw StateError(
        'No local account was found for this email. Sign up first.',
      );
    }
    final salt = account['salt'] as String? ?? '';
    final expected = account['passwordHash'] as String? ?? '';
    final actual = _passwordHash(salt, password);
    if (!_constantTimeEquals(expected, actual)) {
      throw StateError('The email or password is incorrect.');
    }
    await _persistAccountsAndSession(cleanEmail);
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_activeSessionEmailKey);
    _activeUserEmail = null;
    _activeUserName = null;
    notifyListeners();
  }

  bool _isInstitutionalEmail(String email) => RegExp(
    r'^[^\s@]+@lpunetwork\.edu\.ph$',
    caseSensitive: false,
  ).hasMatch(email);

  String _passwordHash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  bool _constantTimeEquals(String first, String second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var i = 0; i < first.length; i++) {
      difference |= first.codeUnitAt(i) ^ second.codeUnitAt(i);
    }
    return difference == 0;
  }

  Future<void> _persistAccountsAndSession(String email) async {
    final preferences = await SharedPreferences.getInstance();
    final accountsSaved = await preferences.setString(
      _authAccountsKey,
      jsonEncode(_authAccounts),
    );
    final sessionSaved = await preferences.setString(
      _activeSessionEmailKey,
      email,
    );
    if (!accountsSaved || !sessionSaved) {
      throw StateError('The account session could not be saved locally.');
    }
    final account = _authAccounts[email] as Map;
    _activeUserEmail = email;
    _activeUserName = account['name'] as String?;
    notifyListeners();
  }

  Future<void> setProfilePhoto(Uint8List? bytes) async {
    final preferences = await SharedPreferences.getInstance();
    if (bytes == null) {
      await preferences.remove(_profilePhotoKey);
      _profilePhotoBase64 = null;
    } else {
      final encoded = base64Encode(bytes);
      final saved = await preferences.setString(_profilePhotoKey, encoded);
      if (!saved) {
        throw StateError('The profile photo could not be saved locally.');
      }
      _profilePhotoBase64 = encoded;
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, enabled);
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setRememberMe(
    bool enabled,
    String userId,
    String password,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_rememberMeKey, enabled);
    if (enabled && userId.trim().isNotEmpty) {
      await preferences.setString(_savedUserIdKey, userId.trim());
    } else {
      await preferences.remove(_savedUserIdKey);
      await preferences.remove(_savedPasswordKey);
    }
    if (enabled && userId.trim().isNotEmpty && password.isNotEmpty) {
      await preferences.setString(_savedPasswordKey, password);
    }
    _rememberMe = enabled;
    _savedUserId = enabled ? userId.trim() : '';
    _savedPassword = enabled ? password : '';
    notifyListeners();
  }

  Future<void> setUseMockData(bool enabled) async {
    _useMockData = enabled;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_mockDataKey, enabled);
    } catch (error) {
      debugPrint('Could not persist mock data preference: $error');
    }
  }

  Future<void> clearLocalStorage() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    _themeMode = ThemeMode.light;
    _useMockData = false;
    _profilePhotoBase64 = null;
    _rememberMe = false;
    _savedUserId = '';
    _savedPassword = '';
    _authAccounts = {};
    _activeUserEmail = null;
    _activeUserName = null;
    notifyListeners();
  }
}
