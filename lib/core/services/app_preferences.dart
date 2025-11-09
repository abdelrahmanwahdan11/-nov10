import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _seenOnboardingKey = 'seen_onboarding';
  static const _primaryColorKey = 'primary_color';
  static const _themeModeKey = 'theme_mode';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get hasSeenOnboarding => _prefs.getBool(_seenOnboardingKey) ?? false;
  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(_seenOnboardingKey, value);
  }

  Color get primaryColor {
    final stored = _prefs.getInt(_primaryColorKey);
    if (stored == null) {
      return const Color(0xFF5F4B8B);
    }
    return Color(stored);
  }

  Future<void> setPrimaryColor(Color color) async {
    await _prefs.setInt(_primaryColorKey, color.value);
  }

  ThemeMode get themeMode {
    final stored = _prefs.getString(_themeModeKey);
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_themeModeKey, value);
  }
}
