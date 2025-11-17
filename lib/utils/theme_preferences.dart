import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const _key = 'theme_mode';

  /// Save ThemeMode
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_key, mode.index);
  }

  /// Load saved ThemeMode, default to system
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key);
    if (index != null && index >= 0 && index <= 2) {
      return ThemeMode.values[index];
    }
    return ThemeMode.system;
  }
}
