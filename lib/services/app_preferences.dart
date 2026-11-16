import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  static const _darkModeKey = 'dark_mode';
  static const _mockDataKey = 'mock_data';
  static const _profilePhotoKey = 'profile_photo';
  static const _rememberMeKey = 'remember_me';
  static const _savedUserIdKey = 'saved_user_id';
  static const _savedPasswordKey = 'saved_password';

  ThemeMode _themeMode = ThemeMode.light;
  bool _useMockData = false;
  bool _rememberMe = false;
  String _savedUserId = '';
  String _savedPassword = '';
  String? _profilePhotoBase64;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get useMockData => _useMockData;
  bool get rememberMe => _rememberMe;
  String get savedUserId => _savedUserId;
  String get savedPassword => _savedPassword;
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
    _profilePhotoBase64 = preferences.getString(_profilePhotoKey);
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
      // Keep the selected source active for this session if local persistence
      // is temporarily unavailable. The UI remains usable and can retry later.
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
    notifyListeners();
  }
}
