import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _seenOnboardingKey = 'seen_onboarding';
  static const _primaryColorKey = 'primary_color';
  static const _themeModeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _favoriteIdsKey = 'favorite_ids';
  static const _comparisonIdsKey = 'comparison_ids';
  static const _showroomMoodKey = 'showroom_mood';
  static const _showroomSceneKey = 'showroom_scene';

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

  Locale get locale {
    final stored = _prefs.getString(_localeKey);
    if (stored == null) {
      return const Locale('ar');
    }
    return Locale(stored);
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_localeKey, locale.languageCode);
  }

  Set<String> getFavoriteIds() {
    final stored = _prefs.getStringList(_favoriteIdsKey);
    return stored?.toSet() ?? <String>{};
  }

  Future<void> setFavoriteIds(Set<String> ids) async {
    await _prefs.setStringList(_favoriteIdsKey, ids.toList());
  }

  Set<String> getComparisonIds() {
    final stored = _prefs.getStringList(_comparisonIdsKey);
    return stored?.toSet() ?? <String>{};
  }

  Future<void> setComparisonIds(Set<String> ids) async {
    await _prefs.setStringList(_comparisonIdsKey, ids.toList());
  }

  String? getShowroomMood() => _prefs.getString(_showroomMoodKey);

  Future<void> setShowroomMood(String? mood) async {
    if (mood == null) {
      await _prefs.remove(_showroomMoodKey);
    } else {
      await _prefs.setString(_showroomMoodKey, mood);
    }
  }

  String? getShowroomScene() => _prefs.getString(_showroomSceneKey);

  Future<void> setShowroomScene(String id) async {
    await _prefs.setString(_showroomSceneKey, id);
  }
}
