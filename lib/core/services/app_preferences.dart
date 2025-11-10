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
  static const _pinnedBlueprintKey = 'pinned_blueprint_id';
  static const _experiencePhasePrefix = 'experience_phase_';
  static const _experienceChronicleKey = 'experience_chronicle';
  static const _experienceFocusKey = 'experience_focus';
  static const _experienceOrbitsKey = 'experience_orbits';
  static const _experienceActiveOrbitKey = 'experience_active_orbit';
  static const _experienceConstellationsKey = 'experience_constellations';
  static const _experienceActiveConstellationKey =
      'experience_active_constellation';
  static const _experienceHorizonsKey = 'experience_horizons';
  static const _experienceActiveHorizonKey = 'experience_active_horizon';
  static const _experienceAurorasKey = 'experience_auroras';
  static const _experienceActiveAuroraKey = 'experience_active_aurora';
  static const _experienceNebulasKey = 'experience_nebulas';
  static const _experienceActiveNebulaKey = 'experience_active_nebula';
  static const _experienceNovasKey = 'experience_novas';
  static const _experienceActiveNovaKey = 'experience_active_nova';
  static const _experienceQuasarsKey = 'experience_quasars';
  static const _experienceActiveQuasarKey = 'experience_active_quasar';
  static const _experienceSingularitiesKey = 'experience_singularities';
  static const _experienceActiveSingularityKey =
      'experience_active_singularity';
  static const _experienceContinuaKey = 'experience_continua';
  static const _experienceActiveContinuumKey =
      'experience_active_continuum';

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

  String? getPinnedBlueprintId() => _prefs.getString(_pinnedBlueprintKey);

  Future<void> setPinnedBlueprintId(String? id) async {
    if (id == null) {
      await _prefs.remove(_pinnedBlueprintKey);
    } else {
      await _prefs.setString(_pinnedBlueprintKey, id);
    }
  }

  double getExperiencePhaseProgress(String key) {
    return _prefs.getDouble('$_experiencePhasePrefix$key') ?? 0;
  }

  Future<void> setExperiencePhaseProgress(String key, double progress) async {
    await _prefs.setDouble('$_experiencePhasePrefix$key', progress);
  }

  Future<void> resetExperiencePhases(Iterable<String> keys) async {
    for (final key in keys) {
      await _prefs.remove('$_experiencePhasePrefix$key');
    }
  }

  List<String> getExperienceChronicle() {
    return _prefs.getStringList(_experienceChronicleKey) ?? <String>[];
  }

  Future<void> setExperienceChronicle(List<String> entries) async {
    await _prefs.setStringList(_experienceChronicleKey, entries);
  }

  Future<void> clearExperienceChronicle() async {
    await _prefs.remove(_experienceChronicleKey);
  }

  String? getExperienceFocus() => _prefs.getString(_experienceFocusKey);

  Future<void> setExperienceFocus(String? encoded) async {
    if (encoded == null) {
      await _prefs.remove(_experienceFocusKey);
    } else {
      await _prefs.setString(_experienceFocusKey, encoded);
    }
  }

  List<String> getExperienceOrbits() {
    return _prefs.getStringList(_experienceOrbitsKey) ?? <String>[];
  }

  Future<void> setExperienceOrbits(List<String> orbits) async {
    await _prefs.setStringList(_experienceOrbitsKey, orbits);
  }

  Future<void> clearExperienceOrbits() async {
    await _prefs.remove(_experienceOrbitsKey);
  }

  String? getActiveOrbitId() => _prefs.getString(_experienceActiveOrbitKey);

  Future<void> setActiveOrbitId(String? id) async {
    if (id == null) {
      await _prefs.remove(_experienceActiveOrbitKey);
    } else {
      await _prefs.setString(_experienceActiveOrbitKey, id);
    }
  }

  List<String> getExperienceConstellations() {
    return _prefs.getStringList(_experienceConstellationsKey) ?? <String>[];
  }

  Future<void> setExperienceConstellations(List<String> constellations) async {
    await _prefs.setStringList(
      _experienceConstellationsKey,
      constellations,
    );
  }

  Future<void> clearExperienceConstellations() async {
    await _prefs.remove(_experienceConstellationsKey);
  }

  String? getActiveConstellationId() =>
      _prefs.getString(_experienceActiveConstellationKey);

  Future<void> setActiveConstellationId(String? id) async {
    if (id == null) {
      await _prefs.remove(_experienceActiveConstellationKey);
    } else {
      await _prefs.setString(_experienceActiveConstellationKey, id);
    }
  }

  List<String> getExperienceHorizons() {
    return _prefs.getStringList(_experienceHorizonsKey) ?? <String>[];
  }

  Future<void> setExperienceHorizons(List<String> horizons) async {
    await _prefs.setStringList(_experienceHorizonsKey, horizons);
  }

  Future<void> clearExperienceHorizons() async {
    await _prefs.remove(_experienceHorizonsKey);
  }

  String? getActiveHorizonId() =>
      _prefs.getString(_experienceActiveHorizonKey);

  Future<void> setActiveHorizonId(String? id) async {
    if (id == null) {
      await _prefs.remove(_experienceActiveHorizonKey);
    } else {
      await _prefs.setString(_experienceActiveHorizonKey, id);
    }
  }

  List<String> getExperienceAuroras() {
    return _prefs.getStringList(_experienceAurorasKey) ?? <String>[];
  }

  Future<void> setExperienceAuroras(List<String> auroras) async {
    await _prefs.setStringList(_experienceAurorasKey, auroras);
  }

  Future<void> clearExperienceAuroras() async {
    await _prefs.remove(_experienceAurorasKey);
  }

  String? getActiveAuroraId() =>
      _prefs.getString(_experienceActiveAuroraKey);

  Future<void> setActiveAuroraId(String? id) async {
    if (id == null) {
      await _prefs.remove(_experienceActiveAuroraKey);
    } else {
      await _prefs.setString(_experienceActiveAuroraKey, id);
    }
  }

  List<String> getExperienceNebulas() {
    return _prefs.getStringList(_experienceNebulasKey) ?? <String>[];
  }

  Future<void> setExperienceNebulas(List<String> nebulas) async {
    await _prefs.setStringList(_experienceNebulasKey, nebulas);
  }

  Future<void> clearExperienceNebulas() async {
    await _prefs.remove(_experienceNebulasKey);
  }

  String? getActiveNebulaId() =>
      _prefs.getString(_experienceActiveNebulaKey);

  Future<void> setActiveNebulaId(String? id) async {
    if (id == null) {
      await _prefs.remove(_experienceActiveNebulaKey);
    } else {
      await _prefs.setString(_experienceActiveNebulaKey, id);
    }
  }

  List<String> getExperienceNovas() {
    return _prefs.getStringList(_experienceNovasKey) ?? <String>[];
  }

  Future<void> setExperienceNovas(List<String> novas) async {
    await _prefs.setStringList(_experienceNovasKey, novas);
  }

  Future<void> clearExperienceNovas() async {
    await _prefs.remove(_experienceNovasKey);
  }

  String? getActiveNovaId() => _prefs.getString(_experienceActiveNovaKey);

  Future<void> setActiveNovaId(String? id) async {
    if (id == null) {
      await _prefs.remove(_experienceActiveNovaKey);
    } else {
      await _prefs.setString(_experienceActiveNovaKey, id);
    }
  }

  List<String> getExperienceQuasars() {
    return _prefs.getStringList(_experienceQuasarsKey) ?? <String>[];
  }

  Future<void> setExperienceQuasars(List<String> quasars) async {
    await _prefs.setStringList(_experienceQuasarsKey, quasars);
  }

  Future<void> clearExperienceQuasars() async {
    await _prefs.remove(_experienceQuasarsKey);
  }

  String? getActiveQuasarId() =>
      _prefs.getString(_experienceActiveQuasarKey);

  Future<void> setActiveQuasarId(String? id) async {
    if (id == null) {
      await _prefs.remove(_experienceActiveQuasarKey);
    } else {
      await _prefs.setString(_experienceActiveQuasarKey, id);
    }
  }

  List<String> getExperienceSingularities() {
    return _prefs.getStringList(_experienceSingularitiesKey) ?? <String>[];
  }

  Future<void> setExperienceSingularities(List<String> singularities) async {
    await _prefs.setStringList(_experienceSingularitiesKey, singularities);
  }

  Future<void> clearExperienceSingularities() async {
    await _prefs.remove(_experienceSingularitiesKey);
  }

  String? getActiveSingularityId() =>
      _prefs.getString(_experienceActiveSingularityKey);

  Future<void> setActiveSingularityId(String? id) async {
    if (id == null) {
      await _prefs.remove(_experienceActiveSingularityKey);
    } else {
      await _prefs.setString(_experienceActiveSingularityKey, id);
    }
  }

  List<String> getExperienceContinua() {
    return _prefs.getStringList(_experienceContinuaKey) ?? <String>[];
  }

  Future<void> setExperienceContinua(List<String> continua) async {
    await _prefs.setStringList(_experienceContinuaKey, continua);
  }

  Future<void> clearExperienceContinua() async {
    await _prefs.remove(_experienceContinuaKey);
  }

  String? getActiveContinuumId() =>
      _prefs.getString(_experienceActiveContinuumKey);

  Future<void> setActiveContinuumId(String? id) async {
    if (id == null) {
      await _prefs.remove(_experienceActiveContinuumKey);
    } else {
      await _prefs.setString(_experienceActiveContinuumKey, id);
    }
  }
}
