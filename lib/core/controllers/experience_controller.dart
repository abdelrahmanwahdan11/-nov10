import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/experience_blueprint.dart';
import '../models/experience_constellation.dart';
import '../models/experience_horizon.dart';
import '../models/experience_moment.dart';
import '../models/experience_orbit.dart';
import '../models/item.dart';
import '../models/showroom_scene.dart';
import '../services/app_preferences.dart';
import 'catalog_controller.dart';
import 'showroom_controller.dart';

class ExperienceController extends ChangeNotifier {
  ExperienceController({
    required CatalogController catalogController,
    required ShowroomController showroomController,
    required AppPreferences preferences,
  })  : _catalogController = catalogController,
        _showroomController = showroomController,
        _preferences = preferences {
    _catalogListener = () {
      _emitPulse();
      _syncConstellations();
      notifyListeners();
    };
    _showroomListener = notifyListeners;
    _catalogController.addListener(_catalogListener);
    _showroomController.addListener(_showroomListener);
    _seedBlueprints();
    _restoreState();
    _schedulePulse();
    _scheduleOrbitCycle();
    _scheduleConstellationDrift();
    _scheduleHorizonSweep();
  }

  final CatalogController _catalogController;
  final ShowroomController _showroomController;
  final AppPreferences _preferences;
  late final VoidCallback _catalogListener;
  late final VoidCallback _showroomListener;
  final List<ExperienceBlueprint> _blueprints = <ExperienceBlueprint>[];
  ExperienceBlueprint? _pinned;
  final Map<String, double> _phaseProgress = <String, double>{};
  final List<ExperienceSignal> _signals = <ExperienceSignal>[];
  final StreamController<ExperienceSignal> _signalController =
      StreamController<ExperienceSignal>.broadcast();
  final Random _random = Random(8);
  Timer? _pulseTimer;
  final List<ExperienceMoment> _chronicle = <ExperienceMoment>[];
  ExperienceFocus? _activeFocus;
  final List<ExperienceOrbit> _orbits = <ExperienceOrbit>[];
  ExperienceOrbit? _activeOrbit;
  Timer? _orbitTimer;
  final List<ExperienceConstellation> _constellations =
      <ExperienceConstellation>[];
  ExperienceConstellation? _activeConstellation;
  Timer? _constellationTimer;
  final List<ExperienceHorizon> _horizons = <ExperienceHorizon>[];
  ExperienceHorizon? _activeHorizon;
  Timer? _horizonTimer;

  List<ExperienceBlueprint> get blueprints => List.unmodifiable(_blueprints);
  ExperienceBlueprint? get pinnedBlueprint => _pinned;
  List<ExperienceSignal> get signals => List.unmodifiable(_signals);
  Stream<ExperienceSignal> get pulseStream => _signalController.stream;
  List<ExperienceMoment> get chronicle => List.unmodifiable(_chronicle);
  ExperienceFocus? get activeFocus => _activeFocus;
  List<ExperienceOrbit> get orbits => List.unmodifiable(_orbits);
  ExperienceOrbit? get activeOrbit => _activeOrbit;
  List<ExperienceConstellation> get constellations =>
      List.unmodifiable(_constellations);
  ExperienceConstellation? get activeConstellation => _activeConstellation;
  List<ExperienceHorizon> get horizons => List.unmodifiable(_horizons);
  ExperienceHorizon? get activeHorizon => _activeHorizon;

  double blueprintProgress(ExperienceBlueprint blueprint) {
    return blueprint.progress(_getPhaseProgress);
  }

  double phaseProgress(String blueprintId, String phaseId) {
    return _getPhaseProgress('$blueprintId::$phaseId');
  }

  List<CatalogItem> resolveItems(ExperienceBlueprint blueprint) {
    return blueprint.relatedItemIds
        .map(_catalogController.findById)
        .whereType<CatalogItem>()
        .toList();
  }

  ShowroomScene? resolveMoodScene(ExperienceBlueprint blueprint) {
    final scenes = _showroomController.allScenes;
    if (scenes.isEmpty) {
      return null;
    }
    return scenes.firstWhere(
      (scene) => scene.mood == blueprint.focusMood,
      orElse: () => scenes.first,
    );
  }

  List<CatalogItem> resolveOrbitItems(ExperienceOrbit orbit) {
    final blueprint = findById(orbit.blueprintId);
    if (blueprint == null) {
      return const <CatalogItem>[];
    }
    return resolveItems(blueprint);
  }

  List<CatalogItem> resolveConstellationItems(
    ExperienceConstellation constellation,
  ) {
    final seen = <String>{};
    final items = <CatalogItem>[];
    for (final blueprintId in constellation.blueprintIds) {
      final blueprint = findById(blueprintId);
      if (blueprint == null) {
        continue;
      }
      for (final itemId in blueprint.relatedItemIds) {
        if (seen.add(itemId)) {
          final item = _catalogController.findById(itemId);
          if (item != null) {
            items.add(item);
          }
        }
      }
    }
    for (final itemId in constellation.anchorItemIds) {
      if (seen.add(itemId)) {
        final item = _catalogController.findById(itemId);
        if (item != null) {
          items.add(item);
        }
      }
    }
    return items;
  }

  List<CatalogItem> resolveHorizonItems(ExperienceHorizon horizon) {
    final seen = <String>{};
    final items = <CatalogItem>[];
    for (final itemId in horizon.passageItemIds) {
      if (!seen.add(itemId)) {
        continue;
      }
      final item = _catalogController.findById(itemId);
      if (item != null) {
        items.add(item);
      }
    }
    if (items.length < 4) {
      for (final constellationId in horizon.constellationIds) {
        ExperienceConstellation? constellation;
        try {
          constellation = _constellations
              .firstWhere((entry) => entry.id == constellationId);
        } catch (_) {
          constellation = null;
        }
        if (constellation == null) {
          continue;
        }
        for (final itemId in constellation.anchorItemIds) {
          if (!seen.add(itemId)) {
            continue;
          }
          final item = _catalogController.findById(itemId);
          if (item != null) {
            items.add(item);
          }
          if (items.length >= 6) {
            break;
          }
        }
        if (items.length >= 6) {
          break;
        }
      }
    }
    return items;
  }

  double horizonIntensity(ExperienceHorizon horizon) {
    final constellationLookup = {
      for (final entry in _constellations) entry.id: entry
    };
    final orbitLookup = {for (final orbit in _orbits) orbit.id: orbit};
    return horizon.intensity(constellationLookup, orbitLookup);
  }

  void activateOrbit(ExperienceOrbit orbit, {bool manual = true}) {
    final index = _orbits.indexWhere((entry) => entry.id == orbit.id);
    if (index == -1) {
      return;
    }
    if (_activeOrbit?.id == orbit.id && !manual) {
      return;
    }
    final now = DateTime.now();
    final updated = _orbits[index].copyWith(lastActivated: now);
    _orbits[index] = updated;
    _activeOrbit = updated;
    _persistOrbits();
    unawaited(_preferences.setActiveOrbitId(updated.id));
    final blueprint = findById(updated.blueprintId);
    if (blueprint != null) {
      final title = manual
          ? 'Manual orbit alignment • محاذاة يدوية'
          : 'Auto orbit cycle • دوران تلقائي';
      final detail =
          'Orbit intensity ${(updated.intensity * 100).toStringAsFixed(0)}% • طاقة المدار';
      _recordMoment(
        ExperienceMoment(
          id: 'orbit_${updated.id}_${now.millisecondsSinceEpoch}',
          blueprintId: blueprint.id,
          kind: ExperienceMomentKind.orbit,
          title: title,
          detail: detail,
          timestamp: now,
          mood: blueprint.focusMood,
        ),
      );
    }
    _scheduleOrbitCycle();
    notifyListeners();
  }

  void cycleOrbit({bool manual = false}) {
    if (_orbits.isEmpty) {
      return;
    }
    final currentIndex = _activeOrbit == null
        ? -1
        : _orbits.indexWhere((orbit) => orbit.id == _activeOrbit!.id);
    final nextIndex = (currentIndex + 1) % _orbits.length;
    activateOrbit(_orbits[nextIndex], manual: manual);
  }

  void alignConstellation(ExperienceConstellation constellation,
      {bool manual = true}) {
    final index =
        _constellations.indexWhere((entry) => entry.id == constellation.id);
    if (index == -1) {
      return;
    }
    if (_activeConstellation?.id == constellation.id && !manual) {
      return;
    }
    final now = DateTime.now();
    final resolved = _constellations[index]
        .copyWith(anchorItemIds: _collectAnchorItems(constellation.blueprintIds));
    final synergy = _calculateConstellationSynergy(resolved);
    final updated = resolved.copyWith(
      synergy: synergy,
      lastAligned: now,
    );
    _constellations[index] = updated;
    _activeConstellation = updated;
    _persistConstellations();
    unawaited(_preferences.setActiveConstellationId(updated.id));
    final orbitLookup = {for (final orbit in _orbits) orbit.id: orbit};
    final energy = updated.energy(orbitLookup);
    final headline = manual
        ? 'Constellation aligned • محاذاة الكوكبة'
        : 'Constellation drift • انجراف الكوكبة';
    final detail =
        '${updated.title} ${(energy * 100).toStringAsFixed(0)}% • طاقة الكوكبة';
    final anchorBlueprintId = updated.blueprintIds.isNotEmpty
        ? updated.blueprintIds.first
        : (_blueprints.isNotEmpty ? _blueprints.first.id : 'bp_serenity');
    _recordMoment(
      ExperienceMoment(
        id: 'constellation_${updated.id}_${now.millisecondsSinceEpoch}',
        blueprintId: anchorBlueprintId,
        kind: ExperienceMomentKind.constellation,
        title: headline,
        detail: detail,
        timestamp: now,
        mood: _resolveConstellationMood(updated),
      ),
    );
    _syncHorizons();
    _scheduleConstellationDrift();
    notifyListeners();
  }

  void cycleConstellation({bool manual = false}) {
    if (_constellations.isEmpty) {
      return;
    }
    final currentIndex = _activeConstellation == null
        ? -1
        : _constellations
            .indexWhere((entry) => entry.id == _activeConstellation!.id);
    final nextIndex = (currentIndex + 1) % _constellations.length;
    alignConstellation(_constellations[nextIndex], manual: manual);
  }

  void openHorizon(ExperienceHorizon horizon, {bool manual = true}) {
    final index = _horizons.indexWhere((entry) => entry.id == horizon.id);
    if (index == -1) {
      return;
    }
    if (_activeHorizon?.id == horizon.id && !manual) {
      return;
    }
    final now = DateTime.now();
    final passages = _collectHorizonPassages(horizon.constellationIds);
    final coherence = _calculateHorizonCoherence(horizon.constellationIds);
    final suggestion = _suggestHorizonBlueprint(horizon.constellationIds);
    final updated = horizon.copyWith(
      passageItemIds: passages,
      coherence: coherence,
      lastExpanded: now,
      suggestedBlueprintId: suggestion,
    );
    _horizons[index] = updated;
    _activeHorizon = updated;
    _persistHorizons();
    unawaited(_preferences.setActiveHorizonId(updated.id));
    final fallbackBlueprintId = _resolveHorizonBlueprintFallback(updated);
    final headline = manual
        ? 'Horizon bridge • جسر الأفق'
        : 'Horizon drift • انجراف الأفق';
    final detail =
        '${(updated.coherence * 100).toStringAsFixed(0)}% coherence • انسجام الجسر';
    _recordMoment(
      ExperienceMoment(
        id: 'horizon_${updated.id}_${now.millisecondsSinceEpoch}',
        blueprintId: suggestion ?? fallbackBlueprintId,
        kind: ExperienceMomentKind.horizon,
        title: headline,
        detail: detail,
        timestamp: now,
        mood: _resolveHorizonMood(updated),
      ),
    );
    _scheduleHorizonSweep();
    notifyListeners();
  }

  void cycleHorizon({bool manual = false}) {
    if (_horizons.isEmpty) {
      return;
    }
    final currentIndex = _activeHorizon == null
        ? -1
        : _horizons.indexWhere((entry) => entry.id == _activeHorizon!.id);
    final nextIndex = (currentIndex + 1) % _horizons.length;
    openHorizon(_horizons[nextIndex], manual: manual);
  }

  void pinBlueprint(ExperienceBlueprint blueprint) {
    if (_pinned?.id == blueprint.id) {
      return;
    }
    _pinned = blueprint;
    unawaited(_preferences.setPinnedBlueprintId(blueprint.id));
    _recordMoment(
      ExperienceMoment(
        id: 'focus_${blueprint.id}_${DateTime.now().millisecondsSinceEpoch}',
        blueprintId: blueprint.id,
        kind: ExperienceMomentKind.focus,
        title: blueprint.title,
        detail: blueprint.subtitle,
        timestamp: DateTime.now(),
        mood: blueprint.focusMood,
      ),
    );
    _emitPulse(force: true);
    notifyListeners();
  }

  void unpinBlueprint() {
    if (_pinned == null) return;
    _pinned = null;
    unawaited(_preferences.setPinnedBlueprintId(null));
    notifyListeners();
  }

  void stepPhase(String blueprintId, String phaseId, {double step = 0.25}) {
    final key = '$blueprintId::$phaseId';
    final next = (_getPhaseProgress(key) + step).clamp(0, 1);
    _phaseProgress[key] = next;
    unawaited(_preferences.setExperiencePhaseProgress(key, next));
    final blueprint = findById(blueprintId);
    final phase = blueprint == null ? null : _findPhase(blueprint, phaseId);
    if (blueprint != null && phase != null) {
      _recordMoment(
        ExperienceMoment(
          id: 'progress_${phase.id}_${DateTime.now().millisecondsSinceEpoch}',
          blueprintId: blueprintId,
          phaseId: phaseId,
          kind: ExperienceMomentKind.progress,
          title: phase.title,
          detail: '${(next * 100).clamp(0, 100).toStringAsFixed(0)}%',
          timestamp: DateTime.now(),
          mood: blueprint.focusMood,
        ),
      );
      if (next >= 1 &&
          _activeFocus?.phaseId == phaseId &&
          _activeFocus?.blueprintId == blueprintId) {
        _recordMoment(
          ExperienceMoment(
            id: 'reflection_${phase.id}_${DateTime.now().millisecondsSinceEpoch}',
            blueprintId: blueprintId,
            phaseId: phaseId,
            kind: ExperienceMomentKind.reflection,
            title: phase.title,
            detail: phase.description,
            timestamp: DateTime.now(),
            mood: blueprint.focusMood,
          ),
        );
        releaseFocus(recordMoment: false);
      }
    }
    if (blueprint != null) {
      final completion = _calculateBlueprintCompletion(blueprint);
      _updateOrbit(
        blueprint.id,
        (orbit) => orbit.copyWith(completion: completion),
      );
    }
    notifyListeners();
  }

  Future<void> refreshBlueprints() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _signals.clear();
    _phaseProgress.clear();
    final keys = _blueprints.expand((blueprint) => blueprint.phaseKeys);
    await _preferences.resetExperiencePhases(keys);
    _chronicle.clear();
    await _preferences.clearExperienceChronicle();
    await _preferences.setExperienceFocus(null);
    _activeFocus = null;
    _resetOrbits();
    await _preferences.clearExperienceOrbits();
    await _preferences.setActiveOrbitId(null);
    _constellations.clear();
    _activeConstellation = null;
    await _preferences.clearExperienceConstellations();
    await _preferences.setActiveConstellationId(null);
    _horizons.clear();
    _activeHorizon = null;
    await _preferences.clearExperienceHorizons();
    await _preferences.setActiveHorizonId(null);
    _initializeOrbits();
    _initializeConstellations();
    _initializeHorizons();
    _scheduleOrbitCycle();
    _scheduleConstellationDrift();
    _scheduleHorizonSweep();
    _emitPulse(force: true);
    notifyListeners();
  }

  ExperienceBlueprint? findById(String id) {
    try {
      return _blueprints.firstWhere((blueprint) => blueprint.id == id);
    } catch (_) {
      return null;
    }
  }

  void _schedulePulse() {
    _pulseTimer?.cancel();
    _pulseTimer = Timer(const Duration(seconds: 9), () {
      _emitPulse();
      _schedulePulse();
    });
  }

  void _scheduleOrbitCycle() {
    _orbitTimer?.cancel();
    if (_orbits.isEmpty) {
      return;
    }
    _orbitTimer = Timer(const Duration(seconds: 16), () {
      cycleOrbit();
      _scheduleOrbitCycle();
    });
  }

  void _scheduleConstellationDrift() {
    _constellationTimer?.cancel();
    if (_constellations.isEmpty) {
      return;
    }
    _constellationTimer = Timer(const Duration(seconds: 28), () {
      cycleConstellation();
      _scheduleConstellationDrift();
    });
  }

  void _scheduleHorizonSweep() {
    _horizonTimer?.cancel();
    if (_horizons.isEmpty) {
      return;
    }
    _horizonTimer = Timer(const Duration(seconds: 36), () {
      cycleHorizon();
      _scheduleHorizonSweep();
    });
  }

  double _getPhaseProgress(String key) {
    if (_phaseProgress.containsKey(key)) {
      return _phaseProgress[key]!;
    }
    final stored = _preferences.getExperiencePhaseProgress(key);
    _phaseProgress[key] = stored;
    return stored;
  }

  void _emitPulse({bool force = false}) {
    if (_blueprints.isEmpty) {
      return;
    }
    final blueprint = _pinned ??
        (_blueprints.isEmpty
            ? null
            : _blueprints[_random.nextInt(_blueprints.length)]);
    if (blueprint == null) return;
    final favorites = _catalogController.favoriteIds.toList();
    final related = blueprint.relatedItemIds
        .where((id) => favorites.contains(id))
        .toList();
    final scene = resolveMoodScene(blueprint);
    if (!force && related.isEmpty && favorites.isEmpty) {
      return;
    }
    final focusItems = related.isNotEmpty
        ? related
        : blueprint.relatedItemIds.take(3).toList();
    final headline = 'Pulse update • نبض التصميم';
    final body = scene == null
        ? 'تم جمع ${focusItems.length} عناصر لإلهام ${blueprint.title}.'
        : 'المشهد ${scene.title} يقترح ${focusItems.length} عناصر مفضلة لتعزيز ${blueprint.subtitle}.';
    final signal = ExperienceSignal(
      id: 'signal_${DateTime.now().millisecondsSinceEpoch}',
      headline: headline,
      body: body,
      generatedAt: DateTime.now(),
      relatedItemIds: focusItems,
      blueprintId: blueprint.id,
    );
    _signals.insert(0, signal);
    if (_signals.length > 8) {
      _signals.removeRange(8, _signals.length);
    }
    _signalController.add(signal);
    _recordMoment(
      ExperienceMoment(
        id: signal.id,
        blueprintId: blueprint.id,
        kind: ExperienceMomentKind.pulse,
        title: headline,
        detail: body,
        timestamp: signal.generatedAt,
        mood: blueprint.focusMood,
      ),
    );
    _updateOrbit(
      blueprint.id,
      (orbit) => orbit.copyWith(
        pulseCount: orbit.pulseCount + 1,
        highlightItemIds: blueprint.relatedItemIds.take(4).toList(),
      ),
    );
    _scheduleOrbitCycle();
    notifyListeners();
  }

  void _restoreState() {
    final pinnedId = _preferences.getPinnedBlueprintId();
    if (pinnedId != null) {
      _pinned = findById(pinnedId);
    }
    final chronicleEntries = _preferences.getExperienceChronicle();
    _chronicle
      ..clear()
      ..addAll(
        chronicleEntries
            .map(ExperienceMoment.fromEncoded)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      );
    final focusEncoded = _preferences.getExperienceFocus();
    if (focusEncoded != null) {
      final focus = ExperienceFocus.fromEncoded(focusEncoded);
      if (findById(focus.blueprintId) != null) {
        _activeFocus = focus;
      }
    }
    for (final blueprint in _blueprints) {
      for (final key in blueprint.phaseKeys) {
        _getPhaseProgress(key);
      }
    }
    _initializeOrbits();
    _initializeConstellations();
    _initializeHorizons();
    _emitPulse(force: true);
  }

  void focusPhase(String blueprintId, String phaseId) {
    final blueprint = findById(blueprintId);
    if (blueprint == null) {
      return;
    }
    final phase = _findPhase(blueprint, phaseId);
    if (phase == null) {
      return;
    }
    if (_activeFocus != null) {
      releaseFocus();
    }
    final focus = ExperienceFocus(
      blueprintId: blueprintId,
      phaseId: phaseId,
      startedAt: DateTime.now(),
    );
    _activeFocus = focus;
    unawaited(_preferences.setExperienceFocus(focus.encode()));
    _recordMoment(
      ExperienceMoment(
        id: 'focus_${phase.id}_${focus.startedAt.millisecondsSinceEpoch}',
        blueprintId: blueprintId,
        phaseId: phaseId,
        kind: ExperienceMomentKind.focus,
        title: phase.title,
        detail: blueprint.subtitle,
        timestamp: focus.startedAt,
        mood: blueprint.focusMood,
      ),
    );
    _syncOrbitFocusState();
    notifyListeners();
  }

  void releaseFocus({bool recordMoment = true}) {
    final focus = _activeFocus;
    if (focus == null) {
      return;
    }
    final blueprint = findById(focus.blueprintId);
    final phase = blueprint == null
        ? null
        : _findPhase(blueprint, focus.phaseId);
    _activeFocus = null;
    unawaited(_preferences.setExperienceFocus(null));
    if (recordMoment && blueprint != null && phase != null) {
      _recordMoment(
        ExperienceMoment(
          id: 'reflection_${phase.id}_${DateTime.now().millisecondsSinceEpoch}',
          blueprintId: blueprint.id,
          phaseId: phase.id,
          kind: ExperienceMomentKind.reflection,
          title: phase.title,
          detail: blueprint.title,
          timestamp: DateTime.now(),
          mood: blueprint.focusMood,
        ),
      );
    }
    _syncOrbitFocusState();
    notifyListeners();
  }

  ExperiencePhase? resolvePhase(String blueprintId, String phaseId) {
    final blueprint = findById(blueprintId);
    if (blueprint == null) {
      return null;
    }
    return _findPhase(blueprint, phaseId);
  }

  ExperiencePhase? _findPhase(
    ExperienceBlueprint blueprint,
    String phaseId,
  ) {
    try {
      return blueprint.phases.firstWhere((phase) => phase.id == phaseId);
    } catch (_) {
      return null;
    }
  }

  void _recordMoment(ExperienceMoment moment) {
    _chronicle.removeWhere((existing) => existing.id == moment.id);
    _chronicle.insert(0, moment);
    if (_chronicle.length > 24) {
      _chronicle.removeRange(24, _chronicle.length);
    }
    unawaited(
      _preferences.setExperienceChronicle(
        _chronicle.map((entry) => entry.encode()).toList(),
      ),
    );
  }

  void _initializeOrbits() {
    final stored = _preferences.getExperienceOrbits();
    final restored = stored
        .map(ExperienceOrbit.fromEncoded)
        .fold<Map<String, ExperienceOrbit>>(<String, ExperienceOrbit>{},
            (map, orbit) {
      map[orbit.blueprintId] = orbit;
      return map;
    });
    _orbits
      ..clear()
      ..addAll(
        _blueprints.map((blueprint) {
          final completion = _calculateBlueprintCompletion(blueprint);
          final base = ExperienceOrbit(
            id: 'orbit_${blueprint.id}',
            blueprintId: blueprint.id,
            title: blueprint.title,
            mood: blueprint.focusMood,
            phaseIds: blueprint.phases.map((phase) => phase.id).toList(),
            highlightItemIds: blueprint.relatedItemIds.take(4).toList(),
            completion: completion,
            hasFocus: _activeFocus?.blueprintId == blueprint.id,
          );
          final restoredOrbit = restored[blueprint.id];
          if (restoredOrbit == null) {
            return base;
          }
          return restoredOrbit.copyWith(
            title: base.title,
            phaseIds: base.phaseIds,
            highlightItemIds: base.highlightItemIds,
            completion: completion,
            hasFocus: base.hasFocus,
          );
        }),
      );
    final activeId = _preferences.getActiveOrbitId();
    if (activeId != null) {
      try {
        _activeOrbit =
            _orbits.firstWhere((orbit) => orbit.id == activeId);
      } catch (_) {
        _activeOrbit = null;
      }
    }
    if (_activeOrbit == null && _orbits.isNotEmpty) {
      _activeOrbit = _orbits.firstWhere(
        (orbit) => orbit.hasFocus,
        orElse: () => _orbits.first,
      );
    }
    _persistOrbits();
    unawaited(
      _preferences.setActiveOrbitId(_activeOrbit?.id),
    );
  }

  void _initializeConstellations() {
    final stored = _preferences.getExperienceConstellations();
    final restored = stored
        .map(ExperienceConstellation.fromEncoded)
        .fold<Map<String, ExperienceConstellation>>(
            <String, ExperienceConstellation>{}, (map, constellation) {
      map[constellation.id] = constellation;
      return map;
    });
    final defaults = <ExperienceConstellation>[
      ExperienceConstellation(
        id: 'constellation_flux',
        title: 'Serenity Flux',
        blueprintIds: const ['bp_serenity', 'bp_pulse'],
        moods: const [SceneMood.serene, SceneMood.vibrant],
        anchorItemIds: _collectAnchorItems(
          const ['bp_serenity', 'bp_pulse'],
        ),
      ),
      ExperienceConstellation(
        id: 'constellation_vector',
        title: 'Vector Bloom',
        blueprintIds: const ['bp_serenity', 'bp_quantum'],
        moods: const [SceneMood.serene, SceneMood.futuristic],
        anchorItemIds: _collectAnchorItems(
          const ['bp_serenity', 'bp_quantum'],
        ),
      ),
      ExperienceConstellation(
        id: 'constellation_pulse',
        title: 'Pulse Nexus',
        blueprintIds: const ['bp_pulse', 'bp_quantum'],
        moods: const [SceneMood.vibrant, SceneMood.futuristic],
        anchorItemIds: _collectAnchorItems(
          const ['bp_pulse', 'bp_quantum'],
        ),
      ),
    ];
    _constellations
      ..clear()
      ..addAll(defaults.map((entry) {
        final restoredEntry = restored[entry.id];
        final withAnchors = entry.copyWith(
          anchorItemIds: _collectAnchorItems(entry.blueprintIds),
        );
        final synergy = restoredEntry == null
            ? _calculateConstellationSynergy(withAnchors)
            : restoredEntry.synergy;
        return withAnchors.copyWith(
          synergy: synergy,
          lastAligned: restoredEntry?.lastAligned,
        );
      }));
    _syncConstellations(persist: false);
    final activeId = _preferences.getActiveConstellationId();
    if (activeId != null) {
      try {
        _activeConstellation =
            _constellations.firstWhere((entry) => entry.id == activeId);
      } catch (_) {
        _activeConstellation = null;
      }
    }
    if (_activeConstellation == null && _constellations.isNotEmpty) {
      _activeConstellation = _constellations.first;
    }
    _persistConstellations();
    unawaited(
      _preferences.setActiveConstellationId(_activeConstellation?.id),
    );
  }

  void _initializeHorizons() {
    final stored = _preferences.getExperienceHorizons();
    final restored = stored
        .map(ExperienceHorizon.fromEncoded)
        .fold<Map<String, ExperienceHorizon>>(
            <String, ExperienceHorizon>{}, (map, horizon) {
      map[horizon.id] = horizon;
      return map;
    });
    final defaults = <ExperienceHorizon>[
      ExperienceHorizon(
        id: 'horizon_prism',
        title: 'Prism Bridge',
        constellationIds: const [
          'constellation_flux',
          'constellation_vector',
        ],
        moodHints: const [SceneMood.serene, SceneMood.vibrant],
        passageItemIds: const <String>[],
      ),
      ExperienceHorizon(
        id: 'horizon_echo',
        title: 'Vector Echo',
        constellationIds: const [
          'constellation_vector',
          'constellation_pulse',
        ],
        moodHints: const [SceneMood.vibrant, SceneMood.futuristic],
        passageItemIds: const <String>[],
      ),
      ExperienceHorizon(
        id: 'horizon_quantum',
        title: 'Quantum Loom',
        constellationIds: const [
          'constellation_flux',
          'constellation_pulse',
          'constellation_vector',
        ],
        moodHints: const [
          SceneMood.serene,
          SceneMood.vibrant,
          SceneMood.futuristic,
        ],
        passageItemIds: const <String>[],
      ),
    ];
    _horizons
      ..clear()
      ..addAll(defaults.map((entry) {
        final restoredEntry = restored[entry.id];
        final passages = _collectHorizonPassages(entry.constellationIds);
        final coherence = restoredEntry?.coherence ??
            _calculateHorizonCoherence(entry.constellationIds);
        final suggestion = restoredEntry?.suggestedBlueprintId ??
            _suggestHorizonBlueprint(entry.constellationIds);
        return ExperienceHorizon(
          id: entry.id,
          title: entry.title,
          constellationIds: entry.constellationIds,
          moodHints: entry.moodHints,
          passageItemIds: passages,
          coherence: coherence,
          lastExpanded: restoredEntry?.lastExpanded,
          suggestedBlueprintId: suggestion,
        );
      }));
    _syncHorizons(persist: false);
    final activeId = _preferences.getActiveHorizonId();
    if (activeId != null) {
      try {
        _activeHorizon =
            _horizons.firstWhere((entry) => entry.id == activeId);
      } catch (_) {
        _activeHorizon = null;
      }
    }
    if (_activeHorizon == null && _horizons.isNotEmpty) {
      _activeHorizon = _horizons.first;
    }
    _persistHorizons();
    unawaited(_preferences.setActiveHorizonId(_activeHorizon?.id));
  }

  void _persistOrbits() {
    unawaited(
      _preferences.setExperienceOrbits(
        _orbits.map((orbit) => orbit.encode()).toList(),
      ),
    );
  }

  void _persistConstellations() {
    unawaited(
      _preferences.setExperienceConstellations(
        _constellations.map((entry) => entry.encode()).toList(),
      ),
    );
  }

  void _persistHorizons() {
    unawaited(
      _preferences.setExperienceHorizons(
        _horizons.map((entry) => entry.encode()).toList(),
      ),
    );
  }

  void _updateOrbit(
    String blueprintId,
    ExperienceOrbit Function(ExperienceOrbit orbit) updater,
  ) {
    final index =
        _orbits.indexWhere((orbit) => orbit.blueprintId == blueprintId);
    if (index == -1) {
      return;
    }
    final updated = updater(_orbits[index]);
    _orbits[index] = updated;
    if (_activeOrbit?.id == updated.id) {
      _activeOrbit = updated;
    }
    _persistOrbits();
    _syncConstellations();
  }

  double _calculateBlueprintCompletion(ExperienceBlueprint blueprint) {
    if (blueprint.phases.isEmpty) {
      return 0;
    }
    final total = blueprint.phases.fold<double>(0, (value, phase) {
      return value +
          _getPhaseProgress('${blueprint.id}::${phase.id}');
    });
    return (total / blueprint.phases.length).clamp(0, 1);
  }

  void _syncOrbitFocusState() {
    final focusBlueprintId = _activeFocus?.blueprintId;
    var changed = false;
    for (var i = 0; i < _orbits.length; i++) {
      final orbit = _orbits[i];
      final shouldFocus = orbit.blueprintId == focusBlueprintId;
      if (orbit.hasFocus != shouldFocus) {
        final updated = orbit.copyWith(hasFocus: shouldFocus);
        _orbits[i] = updated;
        if (_activeOrbit?.id == updated.id) {
          _activeOrbit = updated;
        }
        changed = true;
      }
    }
    if (changed) {
      _persistOrbits();
    }
  }

  void _resetOrbits() {
    for (var i = 0; i < _orbits.length; i++) {
      final orbit = _orbits[i];
      _orbits[i] = orbit.copyWith(
        pulseCount: 0,
        completion: 0,
        hasFocus: false,
        lastActivated: null,
      );
    }
    _activeOrbit = null;
    _persistOrbits();
    unawaited(_preferences.setActiveOrbitId(null));
  }

  void _syncConstellations({bool persist = true}) {
    if (_constellations.isEmpty) {
      return;
    }
    var changed = false;
    for (var i = 0; i < _constellations.length; i++) {
      final base = _constellations[i];
      final anchorUpdated = base.copyWith(
        anchorItemIds: _collectAnchorItems(base.blueprintIds),
      );
      final synergy = _calculateConstellationSynergy(anchorUpdated);
      final recalculated = anchorUpdated.copyWith(synergy: synergy);
      final anchorChanged = !_listMatches(
        base.anchorItemIds,
        recalculated.anchorItemIds,
      );
      if (anchorChanged || (recalculated.synergy - base.synergy).abs() > 0.001) {
        _constellations[i] = recalculated;
        if (_activeConstellation?.id == recalculated.id) {
          _activeConstellation = recalculated;
        }
        changed = true;
      }
    }
    if (persist && changed) {
      _persistConstellations();
    }
    _syncHorizons(persist: persist);
  }

  void _syncHorizons({bool persist = true}) {
    if (_horizons.isEmpty) {
      return;
    }
    var changed = false;
    for (var i = 0; i < _horizons.length; i++) {
      final base = _horizons[i];
      final passages = _collectHorizonPassages(base.constellationIds);
      final coherence = _calculateHorizonCoherence(base.constellationIds);
      final suggestion = _suggestHorizonBlueprint(base.constellationIds);
      final passageChanged = !_listMatches(base.passageItemIds, passages);
      final suggestionChanged = base.suggestedBlueprintId != suggestion;
      if (passageChanged ||
          (coherence - base.coherence).abs() > 0.001 ||
          suggestionChanged) {
        final updated = ExperienceHorizon(
          id: base.id,
          title: base.title,
          constellationIds: base.constellationIds,
          moodHints: base.moodHints,
          passageItemIds: passages,
          coherence: coherence,
          lastExpanded: base.lastExpanded,
          suggestedBlueprintId: suggestion,
        );
        _horizons[i] = updated;
        if (_activeHorizon?.id == updated.id) {
          _activeHorizon = updated;
        }
        changed = true;
      }
    }
    if (persist && changed) {
      _persistHorizons();
    }
  }

  List<String> _collectAnchorItems(List<String> blueprintIds) {
    final seen = <String>{};
    for (final blueprintId in blueprintIds) {
      final blueprint = findById(blueprintId);
      if (blueprint == null) {
        continue;
      }
      for (final itemId in blueprint.relatedItemIds) {
        if (seen.length >= 6) {
          break;
        }
        seen.add(itemId);
      }
    }
    final favorites = _catalogController.favoriteIds;
    final prioritized = seen.toList()
      ..sort((a, b) {
        final aFav = favorites.contains(a);
        final bFav = favorites.contains(b);
        if (aFav == bFav) {
          return a.compareTo(b);
        }
        return aFav ? -1 : 1;
      });
    return prioritized.take(6).toList();
  }

  List<String> _collectHorizonPassages(List<String> constellationIds) {
    final seen = <String>{};
    for (final constellationId in constellationIds) {
      ExperienceConstellation? constellation;
      try {
        constellation =
            _constellations.firstWhere((entry) => entry.id == constellationId);
      } catch (_) {
        constellation = null;
      }
      if (constellation == null) {
        continue;
      }
      for (final itemId in constellation.anchorItemIds) {
        if (seen.length >= 8) {
          break;
        }
        seen.add(itemId);
      }
    }
    final favorites = _catalogController.favoriteIds;
    final prioritized = seen.toList()
      ..sort((a, b) {
        final aFav = favorites.contains(a);
        final bFav = favorites.contains(b);
        if (aFav == bFav) {
          return a.compareTo(b);
        }
        return aFav ? -1 : 1;
      });
    return prioritized.take(8).toList();
  }

  double _calculateConstellationSynergy(
      ExperienceConstellation constellation) {
    final completionScores = constellation.blueprintIds
        .map(findById)
        .whereType<ExperienceBlueprint>()
        .map(_calculateBlueprintCompletion)
        .toList();
    final completionScore = completionScores.isEmpty
        ? 0
        : completionScores.reduce((value, element) => value + element) /
            completionScores.length;
    final favorites = _catalogController.favoriteIds;
    final anchorMatches = constellation.anchorItemIds
        .where((itemId) => favorites.contains(itemId))
        .length;
    final anchorScore = constellation.anchorItemIds.isEmpty
        ? 0
        : anchorMatches / constellation.anchorItemIds.length;
    return (completionScore * 0.6 + anchorScore * 0.4).clamp(0, 1);
  }

  SceneMood _resolveConstellationMood(ExperienceConstellation constellation) {
    if (constellation.moods.isNotEmpty) {
      return constellation.moods.first;
    }
    return SceneMood.serene;
  }

  double _calculateHorizonCoherence(List<String> constellationIds) {
    if (constellationIds.isEmpty) {
      return 0;
    }
    final constellations = <ExperienceConstellation>[];
    for (final constellationId in constellationIds) {
      try {
        constellations
            .add(_constellations.firstWhere((entry) => entry.id == constellationId));
      } catch (_) {
        continue;
      }
    }
    if (constellations.isEmpty) {
      return 0;
    }
    final synergyAvg = constellations
            .map((entry) => entry.synergy)
            .fold<double>(0, (value, element) => value + element) /
        constellations.length;
    final orbitLookup = {for (final orbit in _orbits) orbit.id: orbit};
    final energyAvg = constellations
            .map((entry) => entry.energy(orbitLookup))
            .fold<double>(0, (value, element) => value + element) /
        constellations.length;
    final anchorUnion = <String>{};
    for (final constellation in constellations) {
      anchorUnion.addAll(constellation.anchorItemIds);
    }
    final favorites = _catalogController.favoriteIds;
    final anchorScore = anchorUnion.isEmpty
        ? 0
        : anchorUnion.where(favorites.contains).length / anchorUnion.length;
    return (synergyAvg * 0.5 + energyAvg * 0.35 + anchorScore * 0.15)
        .clamp(0, 1);
  }

  SceneMood _resolveHorizonMood(ExperienceHorizon horizon) {
    if (horizon.moodHints.isNotEmpty) {
      return horizon.moodHints.first;
    }
    final moodCounts = <SceneMood, int>{};
    for (final constellationId in horizon.constellationIds) {
      try {
        final constellation =
            _constellations.firstWhere((entry) => entry.id == constellationId);
        for (final mood in constellation.moods) {
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
        }
      } catch (_) {
        continue;
      }
    }
    if (moodCounts.isEmpty) {
      return SceneMood.serene;
    }
    moodCounts.removeWhere((_, value) => value == 0);
    return moodCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  String _resolveHorizonBlueprintFallback(ExperienceHorizon horizon) {
    for (final constellationId in horizon.constellationIds) {
      try {
        final constellation =
            _constellations.firstWhere((entry) => entry.id == constellationId);
        if (constellation.blueprintIds.isNotEmpty) {
          return constellation.blueprintIds.first;
        }
      } catch (_) {
        continue;
      }
    }
    if (_blueprints.isNotEmpty) {
      return _blueprints.first.id;
    }
    return 'bp_serenity';
  }

  String? _suggestHorizonBlueprint(List<String> constellationIds) {
    final candidateIds = <String>{};
    for (final constellationId in constellationIds) {
      try {
        final constellation =
            _constellations.firstWhere((entry) => entry.id == constellationId);
        candidateIds.addAll(constellation.blueprintIds);
      } catch (_) {
        continue;
      }
    }
    if (candidateIds.isEmpty) {
      return null;
    }
    String? bestId;
    var bestScore = -1.0;
    for (final blueprintId in candidateIds) {
      final blueprint = findById(blueprintId);
      if (blueprint == null) {
        continue;
      }
      final completion = _calculateBlueprintCompletion(blueprint);
      final focusBonus = _activeFocus?.blueprintId == blueprintId ? 0.2 : 0;
      final pinnedBonus = _pinned?.id == blueprintId ? 0.15 : 0;
      final score = completion + focusBonus + pinnedBonus;
      if (score > bestScore) {
        bestScore = score;
        bestId = blueprintId;
      }
    }
    return bestId;
  }

  bool _listMatches(List<String> a, List<String> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  void _seedBlueprints() {
    _blueprints
      ..clear()
      ..addAll([
        ExperienceBlueprint(
          id: 'bp_serenity',
          title: 'Serenity Capsule',
          subtitle: 'طقوس استرخاء مسائية',
          focusMood: SceneMood.serene,
          primaryImage: 'https://images.unsplash.com/photo-1505691723518-36a5ac3be353',
          relatedItemIds: const ['item_1', 'item_5', 'item_9'],
          highlightedInsights: const [
            'إضاءة محيطية منخفضة',
            'مواد طبيعية مستدامة',
            'مقاعد متعددة الوضعيات',
          ],
          phases: const [
            ExperiencePhase(
              id: 'context',
              title: 'تهيئة الأجواء',
              description: 'اختيار نغمة إضاءة دافئة مع تشغيل موسيقى هادئة.',
              estimatedMinutes: 5,
              focusTags: ['ambient', 'lighting'],
            ),
            ExperiencePhase(
              id: 'arrange',
              title: 'تنسيق العناصر',
              description: 'إعادة توزيع الوسائد والغطاء لخلق راحة متوازنة.',
              estimatedMinutes: 12,
              focusTags: ['textile', 'comfort'],
            ),
            ExperiencePhase(
              id: 'immerse',
              title: 'غمر الحواس',
              description: 'تجربة المشهد ثلاثي الأبعاد ومقارنة الإعدادات المختلفة.',
              estimatedMinutes: 8,
              focusTags: ['3d', 'comparison'],
            ),
          ],
        ),
        ExperienceBlueprint(
          id: 'bp_pulse',
          title: 'Pulse Flow',
          subtitle: 'جلسة عرض تفاعلية سريعة',
          focusMood: SceneMood.vibrant,
          primaryImage: 'https://images.unsplash.com/photo-1505691938895-1758d7feb511',
          relatedItemIds: const ['item_3', 'item_12', 'item_14'],
          highlightedInsights: const [
            'عرض بصري متحرك',
            'تفاعل مباشر مع الجمهور',
            'تحكم لحظي في الألوان',
          ],
          phases: const [
            ExperiencePhase(
              id: 'spark',
              title: 'تهيئة الطاقة',
              description: 'اختيار مؤثرات الألوان والحركة قبل بدء العرض.',
              estimatedMinutes: 7,
              focusTags: ['animation', 'lighting'],
            ),
            ExperiencePhase(
              id: 'perform',
              title: 'تشغيل العرض',
              description: 'الانتقال بين العناصر بسرعة مع إبراز التفاصيل المهمة.',
              estimatedMinutes: 15,
              focusTags: ['story', 'tempo'],
            ),
            ExperiencePhase(
              id: 'collect',
              title: 'جمع التعقيبات',
              description: 'تدوين ردود الفعل والمقارنات لحفظها في لوحة الملخص.',
              estimatedMinutes: 6,
              focusTags: ['insights', 'notes'],
            ),
          ],
        ),
        ExperienceBlueprint(
          id: 'bp_quantum',
          title: 'Quantum Habitat',
          subtitle: 'تجربة مستقبلية متكيفة',
          focusMood: SceneMood.futuristic,
          primaryImage: 'https://images.unsplash.com/photo-1524758631624-e2822e304c36',
          relatedItemIds: const ['item_18', 'item_22', 'item_24'],
          highlightedInsights: const [
            'أسطح تفاعلية ذكية',
            'مراقبة حية للراحة',
            'مؤشرات طاقة لحظية',
          ],
          phases: const [
            ExperiencePhase(
              id: 'scan',
              title: 'مسح البيئة',
              description: 'تحديد الاحتياجات الذكية لكل مساحة في المنزل.',
              estimatedMinutes: 10,
              focusTags: ['sensors', 'setup'],
            ),
            ExperiencePhase(
              id: 'simulate',
              title: 'محاكاة متقدمة',
              description: 'تشغيل عرض تفاعلي للمشهد مع تبديل الحالات.',
              estimatedMinutes: 18,
              focusTags: ['simulation', '3d'],
            ),
            ExperiencePhase(
              id: 'sync',
              title: 'مزامنة كاملة',
              description: 'مزامنة التفضيلات مع الكتالوج والمقارنة التلقائية.',
              estimatedMinutes: 9,
              focusTags: ['automation', 'sync'],
            ),
          ],
        ),
      ]);
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _orbitTimer?.cancel();
    _constellationTimer?.cancel();
    _horizonTimer?.cancel();
    _catalogController.removeListener(_catalogListener);
    _showroomController.removeListener(_showroomListener);
    _signalController.close();
    super.dispose();
  }
}
