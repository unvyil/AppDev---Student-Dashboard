import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  static const _darkModeKey = 'dark_mode';
  static const _mockDataKey = 'mock_data';
  static const _profilePhotoKey = 'profile_photo';

  ThemeMode _themeMode = ThemeMode.light;
  bool _useMockData = false;
  String? _profilePhotoBase64;

  ThemeMode get themeMode => _themeMode;
  bool get useMockData => _useMockData;
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
    _themeMode = preferences.getBool(_darkModeKey) ?? false
        ? ThemeMode.dark
        : ThemeMode.light;
    _useMockData = preferences.getBool(_mockDataKey) ?? false;
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

  Future<void> setUseMockData(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_mockDataKey, enabled);
    _useMockData = enabled;
    notifyListeners();
  }

  Future<void> clearLocalStorage() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    _themeMode = ThemeMode.light;
    _useMockData = false;
    _profilePhotoBase64 = null;
    notifyListeners();
  }
}
