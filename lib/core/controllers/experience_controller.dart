import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/experience_aurora.dart';
import '../models/experience_blueprint.dart';
import '../models/experience_constellation.dart';
import '../models/experience_horizon.dart';
import '../models/experience_moment.dart';
import '../models/experience_nebula.dart';
import '../models/experience_nova.dart';
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
    _scheduleAuroraCascade();
    _scheduleNebulaSurge();
    _scheduleNovaBurst();
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
  final List<ExperienceAurora> _auroras = <ExperienceAurora>[];
  ExperienceAurora? _activeAurora;
  Timer? _auroraTimer;
  final List<ExperienceNebula> _nebulas = <ExperienceNebula>[];
  ExperienceNebula? _activeNebula;
  Timer? _nebulaTimer;
  final List<ExperienceNova> _novas = <ExperienceNova>[];
  ExperienceNova? _activeNova;
  Timer? _novaTimer;

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
  List<ExperienceAurora> get auroras => List.unmodifiable(_auroras);
  ExperienceAurora? get activeAurora => _activeAurora;
  List<ExperienceNebula> get nebulas => List.unmodifiable(_nebulas);
  ExperienceNebula? get activeNebula => _activeNebula;
  List<ExperienceNova> get novas => List.unmodifiable(_novas);
  ExperienceNova? get activeNova => _activeNova;

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

  List<CatalogItem> resolveAuroraItems(ExperienceAurora aurora) {
    final seen = <String>{};
    final items = <CatalogItem>[];
    for (final horizonId in aurora.horizonIds) {
      ExperienceHorizon? horizon;
      try {
        horizon = _horizons.firstWhere((entry) => entry.id == horizonId);
      } catch (_) {
        horizon = null;
      }
      if (horizon == null) {
        continue;
      }
      for (final itemId in horizon.passageItemIds) {
        if (!seen.add(itemId)) {
          continue;
        }
        final item = _catalogController.findById(itemId);
        if (item != null) {
          items.add(item);
        }
      }
    }
    for (final itemId in aurora.highlightItemIds) {
      if (!seen.add(itemId)) {
        continue;
      }
      final item = _catalogController.findById(itemId);
      if (item != null) {
        items.add(item);
      }
      if (items.length >= 10) {
        break;
      }
    }
    return items;
  }

  List<CatalogItem> resolveNebulaItems(ExperienceNebula nebula) {
    final seen = <String>{};
    final items = <CatalogItem>[];
    for (final itemId in nebula.pulseItemIds) {
      if (!seen.add(itemId)) {
        continue;
      }
      final item = _catalogController.findById(itemId);
      if (item != null) {
        items.add(item);
      }
      if (items.length >= 10) {
        break;
      }
    }
    if (items.length < 10) {
      for (final auroraId in nebula.auroraIds) {
        ExperienceAurora? aurora;
        try {
          aurora = _auroras.firstWhere((entry) => entry.id == auroraId);
        } catch (_) {
          aurora = null;
        }
        if (aurora == null) {
          continue;
        }
        for (final itemId in aurora.highlightItemIds) {
          if (!seen.add(itemId)) {
            continue;
          }
          final item = _catalogController.findById(itemId);
          if (item != null) {
            items.add(item);
          }
          if (items.length >= 12) {
            break;
          }
        }
        if (items.length >= 12) {
          break;
        }
      }
    }
    return items;
  }

  List<CatalogItem> resolveNovaItems(ExperienceNova nova) {
    final seen = <String>{};
    final items = <CatalogItem>[];
    for (final itemId in nova.catalystItemIds) {
      if (!seen.add(itemId)) {
        continue;
      }
      final item = _catalogController.findById(itemId);
      if (item != null) {
        items.add(item);
      }
      if (items.length >= 10) {
        break;
      }
    }
    if (items.length < 10) {
      for (final nebulaId in nova.nebulaIds) {
        ExperienceNebula? nebula;
        try {
          nebula = _nebulas.firstWhere((entry) => entry.id == nebulaId);
        } catch (_) {
          nebula = null;
        }
        if (nebula == null) {
          continue;
        }
        for (final item in resolveNebulaItems(nebula)) {
          if (!seen.add(item.id)) {
            continue;
          }
          items.add(item);
          if (items.length >= 14) {
            break;
          }
        }
        if (items.length >= 14) {
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

  double auroraLuminance(ExperienceAurora aurora) {
    final horizonLookup = {for (final entry in _horizons) entry.id: entry};
    final constellationLookup = {
      for (final entry in _constellations) entry.id: entry
    };
    final orbitLookup = {for (final orbit in _orbits) orbit.id: orbit};
    return aurora.glow(horizonLookup, constellationLookup, orbitLookup);
  }

  double nebulaClarity(ExperienceNebula nebula) {
    final auroraLookup = {for (final entry in _auroras) entry.id: entry};
    final horizonLookup = {for (final entry in _horizons) entry.id: entry};
    final constellationLookup = {
      for (final entry in _constellations) entry.id: entry
    };
    final orbitLookup = {for (final orbit in _orbits) orbit.id: orbit};
    return nebula.clarity(
      auroraLookup,
      horizonLookup,
      constellationLookup,
      orbitLookup,
    );
  }

  double novaBrilliance(ExperienceNova nova) {
    final nebulaLookup = {for (final entry in _nebulas) entry.id: entry};
    final auroraLookup = {for (final entry in _auroras) entry.id: entry};
    final horizonLookup = {for (final entry in _horizons) entry.id: entry};
    final constellationLookup = {
      for (final entry in _constellations) entry.id: entry
    };
    final orbitLookup = {for (final orbit in _orbits) orbit.id: orbit};
    return nova.brilliance(
      nebulaLookup,
      auroraLookup,
      horizonLookup,
      constellationLookup,
      orbitLookup,
    );
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
    _syncAuroras();
    _scheduleAuroraCascade();
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

  void openAurora(ExperienceAurora aurora, {bool manual = true}) {
    final index = _auroras.indexWhere((entry) => entry.id == aurora.id);
    if (index == -1) {
      return;
    }
    if (_activeAurora?.id == aurora.id && !manual) {
      return;
    }
    final now = DateTime.now();
    final highlights = _collectAuroraHighlights(aurora.horizonIds);
    final radiance = _calculateAuroraRadiance(aurora.horizonIds);
    final resonance = _calculateAuroraResonance(aurora.horizonIds);
    final suggestion = _suggestAuroraBlueprint(aurora.horizonIds);
    final updated = aurora.copyWith(
      highlightItemIds: highlights,
      radiance: radiance,
      resonance: resonance,
      lastGlide: now,
      suggestedBlueprintId: suggestion,
    );
    _auroras[index] = updated;
    _activeAurora = updated;
    _persistAuroras();
    unawaited(_preferences.setActiveAuroraId(updated.id));
    final blueprintId =
        suggestion ?? _resolveAuroraBlueprintFallback(updated);
    final headline = manual
        ? 'Aurora cascade • شفق متدفق'
        : 'Aurora drift • انجراف الشفق';
    final detail =
        '${(updated.radiance * 100).toStringAsFixed(0)}% radiance • توهج الشفق';
    _recordMoment(
      ExperienceMoment(
        id: 'aurora_${updated.id}_${now.millisecondsSinceEpoch}',
        blueprintId: blueprintId,
        kind: ExperienceMomentKind.aurora,
        title: headline,
        detail: detail,
        timestamp: now,
        mood: _resolveAuroraMood(updated),
      ),
    );
    _syncNebulas();
    _scheduleAuroraCascade();
    notifyListeners();
  }

  void cycleAurora({bool manual = false}) {
    if (_auroras.isEmpty) {
      return;
    }
    final currentIndex = _activeAurora == null
        ? -1
        : _auroras.indexWhere((entry) => entry.id == _activeAurora!.id);
    final nextIndex = (currentIndex + 1) % _auroras.length;
    openAurora(_auroras[nextIndex], manual: manual);
  }

  void openNebula(ExperienceNebula nebula, {bool manual = true}) {
    final index = _nebulas.indexWhere((entry) => entry.id == nebula.id);
    if (index == -1) {
      return;
    }
    if (_activeNebula?.id == nebula.id && !manual) {
      return;
    }
    final now = DateTime.now();
    final pulseItems = _collectNebulaPulseItems(nebula.auroraIds);
    final luminosity = _calculateNebulaLuminosity(nebula.auroraIds);
    final cohesion = _calculateNebulaCohesion(nebula.auroraIds);
    final suggestion = _suggestNebulaBlueprint(nebula.auroraIds);
    final updated = nebula.copyWith(
      pulseItemIds: pulseItems,
      luminosity: luminosity,
      cohesion: cohesion,
      lastSurge: now,
      spotlightBlueprintId: suggestion ?? nebula.spotlightBlueprintId,
    );
    _nebulas[index] = updated;
    _activeNebula = updated;
    _persistNebulas();
    unawaited(_preferences.setActiveNebulaId(updated.id));
    final blueprintId =
        updated.spotlightBlueprintId ?? _resolveNebulaBlueprintFallback(updated);
    final headline = manual
        ? 'Nebula surge • اندفاع السديم'
        : 'Nebula drift • انجراف السديم';
    final detail =
        '${(updated.luminosity * 100).toStringAsFixed(0)}% luminosity • ${(updated.cohesion * 100).toStringAsFixed(0)}% cohesion';
    _recordMoment(
      ExperienceMoment(
        id: 'nebula_${updated.id}_${now.millisecondsSinceEpoch}',
        blueprintId: blueprintId,
        kind: ExperienceMomentKind.nebula,
        title: headline,
        detail: detail,
        timestamp: now,
        mood: _resolveNebulaMood(updated),
      ),
    );
    _syncNovas();
    _scheduleNebulaSurge();
    notifyListeners();
  }

  void cycleNebula({bool manual = false}) {
    if (_nebulas.isEmpty) {
      return;
    }
    final currentIndex = _activeNebula == null
        ? -1
        : _nebulas.indexWhere((entry) => entry.id == _activeNebula!.id);
    final nextIndex = (currentIndex + 1) % _nebulas.length;
    openNebula(_nebulas[nextIndex], manual: manual);
  }

  void openNova(ExperienceNova nova, {bool manual = true}) {
    final index = _novas.indexWhere((entry) => entry.id == nova.id);
    if (index == -1) {
      return;
    }
    if (_activeNova?.id == nova.id && !manual) {
      return;
    }
    final now = DateTime.now();
    final catalystItems = _collectNovaCatalystItems(nova.nebulaIds);
    final intensity = _calculateNovaIntensity(nova.nebulaIds);
    final stability = _calculateNovaStability(nova.nebulaIds);
    final featured = _suggestNovaNebula(nova.nebulaIds);
    final updated = nova.copyWith(
      catalystItemIds: catalystItems,
      intensity: intensity,
      stability: stability,
      lastIgnition: now,
      featuredNebulaId: featured ?? nova.featuredNebulaId,
    );
    _novas[index] = updated;
    _activeNova = updated;
    _persistNovas();
    unawaited(_preferences.setActiveNovaId(updated.id));
    final blueprintId = _resolveNovaBlueprintId(updated);
    final headline = manual
        ? 'Nova ignition • إشعال النوفا'
        : 'Nova drift • انسياب النوفا';
    final detail =
        '${(updated.intensity * 100).toStringAsFixed(0)}% intensity • ${(updated.stability * 100).toStringAsFixed(0)}% stability • ${(novaBrilliance(updated) * 100).toStringAsFixed(0)}% brilliance';
    _recordMoment(
      ExperienceMoment(
        id: 'nova_${updated.id}_${now.millisecondsSinceEpoch}',
        blueprintId: blueprintId,
        kind: ExperienceMomentKind.nova,
        title: headline,
        detail: detail,
        timestamp: now,
        mood: _resolveNovaMood(updated),
      ),
    );
    _scheduleNovaBurst();
    notifyListeners();
  }

  void cycleNova({bool manual = false}) {
    if (_novas.isEmpty) {
      return;
    }
    final currentIndex =
        _activeNova == null ? -1 : _novas.indexWhere((entry) => entry.id == _activeNova!.id);
    final nextIndex = (currentIndex + 1) % _novas.length;
    openNova(_novas[nextIndex], manual: manual);
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
    _auroras.clear();
    _activeAurora = null;
    await _preferences.clearExperienceAuroras();
    await _preferences.setActiveAuroraId(null);
    _nebulas.clear();
    _activeNebula = null;
    await _preferences.clearExperienceNebulas();
    await _preferences.setActiveNebulaId(null);
    _novas.clear();
    _activeNova = null;
    await _preferences.clearExperienceNovas();
    await _preferences.setActiveNovaId(null);
    _initializeOrbits();
    _initializeConstellations();
    _initializeHorizons();
    _initializeAuroras();
    _initializeNebulas();
    _initializeNovas();
    _scheduleOrbitCycle();
    _scheduleConstellationDrift();
    _scheduleHorizonSweep();
    _scheduleAuroraCascade();
    _scheduleNebulaSurge();
    _scheduleNovaBurst();
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

  void _scheduleAuroraCascade() {
    _auroraTimer?.cancel();
    if (_auroras.isEmpty) {
      return;
    }
    final seconds = 48 + _random.nextInt(24);
    _auroraTimer = Timer(Duration(seconds: seconds), () {
      cycleAurora();
      _scheduleAuroraCascade();
    });
  }

  void _scheduleNebulaSurge() {
    _nebulaTimer?.cancel();
    if (_nebulas.isEmpty) {
      return;
    }
    final seconds = 62 + _random.nextInt(36);
    _nebulaTimer = Timer(Duration(seconds: seconds), () {
      cycleNebula();
      _scheduleNebulaSurge();
    });
  }

  void _scheduleNovaBurst() {
    _novaTimer?.cancel();
    if (_novas.isEmpty) {
      return;
    }
    final seconds = 86 + _random.nextInt(42);
    _novaTimer = Timer(Duration(seconds: seconds), () {
      cycleNova();
      _scheduleNovaBurst();
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
    _initializeAuroras();
    _initializeNebulas();
    _initializeNovas();
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

  void _initializeAuroras() {
    final stored = _preferences.getExperienceAuroras();
    final restored = stored
        .map(ExperienceAurora.fromEncoded)
        .fold<Map<String, ExperienceAurora>>(
            <String, ExperienceAurora>{}, (map, aurora) {
      map[aurora.id] = aurora;
      return map;
    });
    final defaults = <ExperienceAurora>[
      ExperienceAurora(
        id: 'aurora_dawn',
        title: 'Dawn Cascade',
        horizonIds: const ['horizon_prism', 'horizon_echo'],
        moodHints: const [SceneMood.serene, SceneMood.vibrant],
        highlightItemIds: const <String>[],
      ),
      ExperienceAurora(
        id: 'aurora_pulse',
        title: 'Pulse Corridor',
        horizonIds: const ['horizon_echo', 'horizon_quantum'],
        moodHints: const [SceneMood.vibrant, SceneMood.futuristic],
        highlightItemIds: const <String>[],
      ),
      ExperienceAurora(
        id: 'aurora_vault',
        title: 'Lumen Vault',
        horizonIds: const [
          'horizon_prism',
          'horizon_quantum',
        ],
        moodHints: const [SceneMood.serene, SceneMood.futuristic],
        highlightItemIds: const <String>[],
      ),
    ];
    _auroras
      ..clear()
      ..addAll(defaults.map((entry) {
        final restoredEntry = restored[entry.id];
        final highlights = _collectAuroraHighlights(entry.horizonIds);
        final radiance = restoredEntry?.radiance ??
            _calculateAuroraRadiance(entry.horizonIds);
        final resonance = restoredEntry?.resonance ??
            _calculateAuroraResonance(entry.horizonIds);
        final suggestion = restoredEntry?.suggestedBlueprintId ??
            _suggestAuroraBlueprint(entry.horizonIds);
        return ExperienceAurora(
          id: entry.id,
          title: entry.title,
          horizonIds: entry.horizonIds,
          moodHints: entry.moodHints,
          highlightItemIds: highlights,
          radiance: radiance,
          resonance: resonance,
          lastGlide: restoredEntry?.lastGlide,
          suggestedBlueprintId: suggestion,
        );
      }));
    _syncAuroras(persist: false);
    final activeId = _preferences.getActiveAuroraId();
    if (activeId != null) {
      try {
        _activeAurora = _auroras.firstWhere((entry) => entry.id == activeId);
      } catch (_) {
        _activeAurora = null;
      }
    }
    if (_activeAurora == null && _auroras.isNotEmpty) {
      _activeAurora = _auroras.first;
    }
    _persistAuroras();
    unawaited(_preferences.setActiveAuroraId(_activeAurora?.id));
  }

  void _initializeNebulas() {
    final stored = _preferences.getExperienceNebulas();
    final restored = stored
        .map(ExperienceNebula.fromEncoded)
        .fold<Map<String, ExperienceNebula>>(
            <String, ExperienceNebula>{}, (map, nebula) {
      map[nebula.id] = nebula;
      return map;
    });
    final defaults = <ExperienceNebula>[
      ExperienceNebula(
        id: 'nebula_chronicle',
        title: 'Chronicle Veil',
        auroraIds: const ['aurora_dawn', 'aurora_pulse'],
        pulseItemIds: const <String>[],
        spectrumHints: const [SceneMood.serene, SceneMood.vibrant],
      ),
      ExperienceNebula(
        id: 'nebula_resonance',
        title: 'Resonance Loom',
        auroraIds: const ['aurora_pulse', 'aurora_vault'],
        pulseItemIds: const <String>[],
        spectrumHints: const [SceneMood.vibrant, SceneMood.futuristic],
      ),
      ExperienceNebula(
        id: 'nebula_horizon',
        title: 'Horizon Chorus',
        auroraIds: const ['aurora_dawn', 'aurora_vault'],
        pulseItemIds: const <String>[],
        spectrumHints: const [SceneMood.serene, SceneMood.futuristic],
      ),
    ];
    _nebulas
      ..clear()
      ..addAll(defaults.map((entry) {
        final restoredEntry = restored[entry.id];
        final pulseItems = restoredEntry?.pulseItemIds.isNotEmpty == true
            ? restoredEntry!.pulseItemIds
            : _collectNebulaPulseItems(entry.auroraIds);
        final luminosity = restoredEntry?.luminosity ??
            _calculateNebulaLuminosity(entry.auroraIds);
        final cohesion = restoredEntry?.cohesion ??
            _calculateNebulaCohesion(entry.auroraIds);
        final spotlight = restoredEntry?.spotlightBlueprintId ??
            _suggestNebulaBlueprint(entry.auroraIds);
        return ExperienceNebula(
          id: entry.id,
          title: entry.title,
          auroraIds: entry.auroraIds,
          pulseItemIds: pulseItems,
          spectrumHints: entry.spectrumHints,
          luminosity: luminosity,
          cohesion: cohesion,
          lastSurge: restoredEntry?.lastSurge,
          spotlightBlueprintId: spotlight,
        );
      }));
    _syncNebulas(persist: false);
    final activeId = _preferences.getActiveNebulaId();
    if (activeId != null) {
      try {
        _activeNebula = _nebulas.firstWhere((entry) => entry.id == activeId);
      } catch (_) {
        _activeNebula = null;
      }
    }
    if (_activeNebula == null && _nebulas.isNotEmpty) {
      _activeNebula = _nebulas.first;
    }
    _persistNebulas();
    unawaited(_preferences.setActiveNebulaId(_activeNebula?.id));
  }

  void _initializeNovas() {
    final stored = _preferences.getExperienceNovas();
    final restored = stored
        .map(ExperienceNova.fromEncoded)
        .fold<Map<String, ExperienceNova>>(<String, ExperienceNova>{}, (map, nova) {
      map[nova.id] = nova;
      return map;
    });
    final defaults = <ExperienceNova>[
      ExperienceNova(
        id: 'nova_orchestra',
        title: 'Nova Orchestra',
        nebulaIds: const ['nebula_chronicle', 'nebula_resonance'],
        catalystItemIds: const <String>[],
        sequenceHints: const [SceneMood.vibrant, SceneMood.futuristic],
      ),
      ExperienceNova(
        id: 'nova_halo',
        title: 'Halo Bloom',
        nebulaIds: const ['nebula_resonance', 'nebula_horizon'],
        catalystItemIds: const <String>[],
        sequenceHints: const [SceneMood.serene, SceneMood.vibrant],
      ),
    ];
    _novas
      ..clear()
      ..addAll(defaults.map((entry) {
        final restoredEntry = restored[entry.id];
        final catalyst = restoredEntry?.catalystItemIds.isNotEmpty == true
            ? restoredEntry!.catalystItemIds
            : _collectNovaCatalystItems(entry.nebulaIds);
        final intensity =
            restoredEntry?.intensity ?? _calculateNovaIntensity(entry.nebulaIds);
        final stability =
            restoredEntry?.stability ?? _calculateNovaStability(entry.nebulaIds);
        final featured = restoredEntry?.featuredNebulaId ??
            _suggestNovaNebula(entry.nebulaIds);
        return ExperienceNova(
          id: entry.id,
          title: entry.title,
          nebulaIds: entry.nebulaIds,
          catalystItemIds: catalyst,
          sequenceHints: entry.sequenceHints,
          intensity: intensity,
          stability: stability,
          lastIgnition: restoredEntry?.lastIgnition,
          featuredNebulaId: featured,
        );
      }));
    _syncNovas(persist: false);
    final activeId = _preferences.getActiveNovaId();
    if (activeId != null) {
      try {
        _activeNova = _novas.firstWhere((entry) => entry.id == activeId);
      } catch (_) {
        _activeNova = null;
      }
    }
    if (_activeNova == null && _novas.isNotEmpty) {
      _activeNova = _novas.first;
    }
    _persistNovas();
    unawaited(_preferences.setActiveNovaId(_activeNova?.id));
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

  void _persistAuroras() {
    if (_auroras.isEmpty) {
      unawaited(_preferences.clearExperienceAuroras());
      return;
    }
    unawaited(
      _preferences.setExperienceAuroras(
        _auroras.map((entry) => entry.encode()).toList(),
      ),
    );
  }

  void _persistNebulas() {
    if (_nebulas.isEmpty) {
      unawaited(_preferences.clearExperienceNebulas());
      return;
    }
    unawaited(
      _preferences.setExperienceNebulas(
        _nebulas.map((entry) => entry.encode()).toList(),
      ),
    );
  }

  void _persistNovas() {
    if (_novas.isEmpty) {
      unawaited(_preferences.clearExperienceNovas());
      return;
    }
    unawaited(
      _preferences.setExperienceNovas(
        _novas.map((entry) => entry.encode()).toList(),
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
    _syncAuroras(persist: persist);
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

  List<String> _collectAuroraHighlights(List<String> horizonIds) {
    final seen = <String>{};
    final highlights = <String>[];
    for (final horizonId in horizonIds) {
      ExperienceHorizon? horizon;
      try {
        horizon = _horizons.firstWhere((entry) => entry.id == horizonId);
      } catch (_) {
        horizon = null;
      }
      if (horizon == null) {
        continue;
      }
      for (final itemId in horizon.passageItemIds) {
        if (seen.add(itemId)) {
          highlights.add(itemId);
        }
        if (highlights.length >= 12) {
          break;
        }
      }
      if (highlights.length >= 12) {
        break;
      }
      final blueprintId =
          horizon.suggestedBlueprintId ?? _resolveHorizonBlueprintFallback(horizon);
      final blueprint = findById(blueprintId);
      if (blueprint != null) {
        for (final itemId in blueprint.relatedItemIds) {
          if (seen.add(itemId)) {
            highlights.add(itemId);
          }
          if (highlights.length >= 12) {
            break;
          }
        }
      }
      if (highlights.length >= 12) {
        break;
      }
    }
    return highlights.take(12).toList();
  }

  List<String> _collectNebulaPulseItems(List<String> auroraIds) {
    final seen = <String>{};
    final items = <String>[];
    for (final auroraId in auroraIds) {
      ExperienceAurora? aurora;
      try {
        aurora = _auroras.firstWhere((entry) => entry.id == auroraId);
      } catch (_) {
        aurora = null;
      }
      if (aurora == null) {
        continue;
      }
      final highlights = _collectAuroraHighlights(aurora.horizonIds);
      for (final itemId in highlights) {
        if (seen.add(itemId)) {
          items.add(itemId);
        }
        if (items.length >= 14) {
          break;
        }
      }
      if (items.length >= 14) {
        break;
      }
      if (aurora.suggestedBlueprintId != null) {
        final blueprint = findById(aurora.suggestedBlueprintId!);
        if (blueprint != null) {
          for (final itemId in blueprint.relatedItemIds) {
            if (seen.add(itemId)) {
              items.add(itemId);
            }
            if (items.length >= 14) {
              break;
            }
          }
        }
      }
    }
    if (items.length < 8 && _pinned != null) {
      for (final itemId in _pinned!.relatedItemIds) {
        if (seen.add(itemId)) {
          items.add(itemId);
        }
        if (items.length >= 14) {
          break;
        }
      }
    }
    if (items.length < 8 && _activeConstellation != null) {
      for (final itemId in _activeConstellation!.anchorItemIds) {
        if (seen.add(itemId)) {
          items.add(itemId);
        }
        if (items.length >= 14) {
          break;
        }
      }
    }
    return items.take(14).toList();
  }

  double _calculateNebulaLuminosity(List<String> auroraIds) {
    if (auroraIds.isEmpty) {
      return 0;
    }
    final radianceScores = <double>[];
    final intensityScores = <double>[];
    for (final auroraId in auroraIds) {
      ExperienceAurora? aurora;
      try {
        aurora = _auroras.firstWhere((entry) => entry.id == auroraId);
      } catch (_) {
        aurora = null;
      }
      if (aurora == null) {
        continue;
      }
      radianceScores.add(aurora.radiance * 0.6 + aurora.resonance * 0.4);
      for (final horizonId in aurora.horizonIds) {
        ExperienceHorizon? horizon;
        try {
          horizon = _horizons.firstWhere((entry) => entry.id == horizonId);
        } catch (_) {
          horizon = null;
        }
        if (horizon == null) {
          continue;
        }
        intensityScores.add(horizonIntensity(horizon));
      }
    }
    final radianceAverage = radianceScores.isEmpty
        ? 0
        : radianceScores.reduce((value, element) => value + element) /
            radianceScores.length;
    final intensityAverage = intensityScores.isEmpty
        ? 0
        : intensityScores.reduce((value, element) => value + element) /
            intensityScores.length;
    return (radianceAverage * 0.65 + intensityAverage * 0.35).clamp(0, 1);
  }

  double _calculateNebulaCohesion(List<String> auroraIds) {
    if (auroraIds.isEmpty) {
      return 0;
    }
    final horizonIds = <String>{};
    final blueprintIds = <String>{};
    final moods = <SceneMood>{};
    for (final auroraId in auroraIds) {
      ExperienceAurora? aurora;
      try {
        aurora = _auroras.firstWhere((entry) => entry.id == auroraId);
      } catch (_) {
        aurora = null;
      }
      if (aurora == null) {
        continue;
      }
      horizonIds.addAll(aurora.horizonIds);
      if (aurora.suggestedBlueprintId != null) {
        blueprintIds.add(aurora.suggestedBlueprintId!);
      }
      moods.addAll(aurora.moodHints);
    }
    final horizonScore = _horizons.isEmpty
        ? 0
        : (horizonIds.length / _horizons.length).clamp(0, 1);
    final completionScores = blueprintIds
        .map(findById)
        .whereType<ExperienceBlueprint>()
        .map(_calculateBlueprintCompletion)
        .toList();
    final completionScore = completionScores.isEmpty
        ? 0
        : completionScores.reduce((value, element) => value + element) /
            completionScores.length;
    final moodScore = moods.isEmpty ? 0 : (moods.length / 4).clamp(0, 1);
    return (horizonScore * 0.4 + completionScore * 0.4 + moodScore * 0.2)
        .clamp(0, 1);
  }

  SceneMood _resolveNebulaMood(ExperienceNebula nebula) {
    if (nebula.spectrumHints.isNotEmpty) {
      return nebula.spectrumHints.first;
    }
    final moodCounts = <SceneMood, int>{};
    for (final auroraId in nebula.auroraIds) {
      ExperienceAurora? aurora;
      try {
        aurora = _auroras.firstWhere((entry) => entry.id == auroraId);
      } catch (_) {
        aurora = null;
      }
      if (aurora == null) {
        continue;
      }
      for (final mood in aurora.moodHints) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }
    if (moodCounts.isEmpty) {
      return SceneMood.serene;
    }
    return moodCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  String _resolveNebulaBlueprintFallback(ExperienceNebula nebula) {
    for (final auroraId in nebula.auroraIds) {
      try {
        final aurora = _auroras.firstWhere((entry) => entry.id == auroraId);
        if (aurora.suggestedBlueprintId != null) {
          return aurora.suggestedBlueprintId!;
        }
      } catch (_) {
        continue;
      }
    }
    if (_pinned != null) {
      return _pinned!.id;
    }
    if (_activeConstellation != null &&
        _activeConstellation!.blueprintIds.isNotEmpty) {
      return _activeConstellation!.blueprintIds.first;
    }
    if (_blueprints.isNotEmpty) {
      return _blueprints.first.id;
    }
    return 'bp_serenity';
  }

  String? _suggestNebulaBlueprint(List<String> auroraIds) {
    final candidateIds = <String>{};
    for (final auroraId in auroraIds) {
      ExperienceAurora? aurora;
      try {
        aurora = _auroras.firstWhere((entry) => entry.id == auroraId);
      } catch (_) {
        aurora = null;
      }
      if (aurora == null) {
        continue;
      }
      if (aurora.suggestedBlueprintId != null) {
        candidateIds.add(aurora.suggestedBlueprintId!);
      }
      for (final horizonId in aurora.horizonIds) {
        ExperienceHorizon? horizon;
        try {
          horizon = _horizons.firstWhere((entry) => entry.id == horizonId);
        } catch (_) {
          horizon = null;
        }
        if (horizon?.suggestedBlueprintId != null) {
          candidateIds.add(horizon!.suggestedBlueprintId!);
        }
      }
    }
    if (_pinned != null) {
      candidateIds.add(_pinned!.id);
    }
    if (candidateIds.isEmpty) {
      return null;
    }
    String? bestId;
    var bestScore = -1.0;
    final favorites = _catalogController.favoriteIds;
    for (final blueprintId in candidateIds) {
      final blueprint = findById(blueprintId);
      if (blueprint == null) {
        continue;
      }
      final completion = _calculateBlueprintCompletion(blueprint);
      final focusBonus = _activeFocus?.blueprintId == blueprintId ? 0.18 : 0;
      final pinnedBonus = _pinned?.id == blueprintId ? 0.12 : 0;
      final favoriteBonus = blueprint.relatedItemIds
              .where((itemId) => favorites.contains(itemId))
              .isNotEmpty
          ? 0.1
          : 0;
      final score = completion + focusBonus + pinnedBonus + favoriteBonus;
      if (score > bestScore) {
        bestScore = score;
        bestId = blueprintId;
      }
    }
    return bestId;
  }

  List<String> _collectNovaCatalystItems(List<String> nebulaIds) {
    final seen = <String>{};
    final items = <String>[];
    for (final nebulaId in nebulaIds) {
      ExperienceNebula? nebula;
      try {
        nebula = _nebulas.firstWhere((entry) => entry.id == nebulaId);
      } catch (_) {
        nebula = null;
      }
      if (nebula == null) {
        continue;
      }
      for (final itemId in nebula.pulseItemIds) {
        if (seen.add(itemId)) {
          items.add(itemId);
        }
        if (items.length >= 12) {
          break;
        }
      }
      if (items.length >= 12) {
        break;
      }
      for (final auroraId in nebula.auroraIds) {
        ExperienceAurora? aurora;
        try {
          aurora = _auroras.firstWhere((entry) => entry.id == auroraId);
        } catch (_) {
          aurora = null;
        }
        if (aurora == null) {
          continue;
        }
        for (final itemId in aurora.highlightItemIds) {
          if (seen.add(itemId)) {
            items.add(itemId);
          }
          if (items.length >= 12) {
            break;
          }
        }
        if (items.length >= 12) {
          break;
        }
      }
      if (items.length >= 12) {
        break;
      }
    }
    if (items.length < 6) {
      final favorites = _catalogController.favoriteIds;
      for (final itemId in favorites) {
        if (seen.add(itemId)) {
          items.add(itemId);
        }
        if (items.length >= 12) {
          break;
        }
      }
    }
    return items.take(12).toList();
  }

  double _calculateNovaIntensity(List<String> nebulaIds) {
    if (nebulaIds.isEmpty) {
      return 0.4;
    }
    final luminosities = <double>[];
    for (final nebulaId in nebulaIds) {
      try {
        final nebula = _nebulas.firstWhere((entry) => entry.id == nebulaId);
        luminosities.add(nebula.luminosity);
      } catch (_) {
        continue;
      }
    }
    if (luminosities.isEmpty) {
      return 0.4;
    }
    final average =
        luminosities.reduce((value, element) => value + element) / luminosities.length;
    final synergyBoost = (nebulaIds.length - 1) * 0.05;
    return (average + synergyBoost).clamp(0, 1);
  }

  double _calculateNovaStability(List<String> nebulaIds) {
    if (nebulaIds.isEmpty) {
      return 0.35;
    }
    final now = DateTime.now();
    final stabilityValues = <double>[];
    for (final nebulaId in nebulaIds) {
      ExperienceNebula? nebula;
      try {
        nebula = _nebulas.firstWhere((entry) => entry.id == nebulaId);
      } catch (_) {
        nebula = null;
      }
      if (nebula == null) {
        continue;
      }
      final recency = nebula.lastSurge == null
          ? 0.3
          : (1 - (now.difference(nebula.lastSurge!).inMinutes / 240).clamp(0, 1)) * 0.4;
      stabilityValues
          .add((nebula.cohesion * 0.6 + recency).clamp(0, 1));
    }
    if (stabilityValues.isEmpty) {
      return 0.35;
    }
    final average = stabilityValues.reduce((value, element) => value + element) /
        stabilityValues.length;
    return average.clamp(0, 1);
  }

  SceneMood _resolveNovaMood(ExperienceNova nova) {
    final featuredId =
        nova.featuredNebulaId ?? (nova.nebulaIds.isNotEmpty ? nova.nebulaIds.first : null);
    if (featuredId != null) {
      try {
        final nebula = _nebulas.firstWhere((entry) => entry.id == featuredId);
        return _resolveNebulaMood(nebula);
      } catch (_) {
        // ignore and fallback to hints
      }
    }
    return nova.sequenceHints.isNotEmpty ? nova.sequenceHints.first : SceneMood.serene;
  }

  String _resolveNovaBlueprintId(ExperienceNova nova) {
    final fallback = _pinned?.id ?? (_blueprints.isNotEmpty ? _blueprints.first.id : 'bp_serenity');
    final featuredId =
        nova.featuredNebulaId ?? (nova.nebulaIds.isNotEmpty ? nova.nebulaIds.first : null);
    if (featuredId == null) {
      return fallback;
    }
    try {
      final nebula = _nebulas.firstWhere((entry) => entry.id == featuredId);
      final blueprintId =
          nebula.spotlightBlueprintId ?? _resolveNebulaBlueprintFallback(nebula);
      return blueprintId.isEmpty ? fallback : blueprintId;
    } catch (_) {
      return fallback;
    }
  }

  String? _suggestNovaNebula(List<String> nebulaIds) {
    String? bestId;
    var bestScore = -1.0;
    final now = DateTime.now();
    for (final nebulaId in nebulaIds) {
      ExperienceNebula? nebula;
      try {
        nebula = _nebulas.firstWhere((entry) => entry.id == nebulaId);
      } catch (_) {
        nebula = null;
      }
      if (nebula == null) {
        continue;
      }
      final clarityScore = nebulaClarity(nebula);
      final recency = nebula.lastSurge == null
          ? 0.2
          : (1 - (now.difference(nebula.lastSurge!).inMinutes / 360).clamp(0, 1)) * 0.3;
      final score = clarityScore + (nebula.luminosity * 0.2) + recency;
      if (score > bestScore) {
        bestScore = score;
        bestId = nebulaId;
      }
    }
    return bestId;
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

  double _calculateAuroraRadiance(List<String> horizonIds) {
    if (horizonIds.isEmpty) {
      return 0;
    }
    final horizons = <ExperienceHorizon>[];
    for (final horizonId in horizonIds) {
      try {
        horizons.add(_horizons.firstWhere((entry) => entry.id == horizonId));
      } catch (_) {
        continue;
      }
    }
    if (horizons.isEmpty) {
      return 0;
    }
    final constellationLookup =
        {for (final entry in _constellations) entry.id: entry};
    final orbitLookup = {for (final orbit in _orbits) orbit.id: orbit};
    final intensityAvg = horizons
            .map((entry) => entry.intensity(constellationLookup, orbitLookup))
            .fold<double>(0, (value, element) => value + element) /
        horizons.length;
    final coherenceAvg = horizons
            .map((entry) => entry.coherence)
            .fold<double>(0, (value, element) => value + element) /
        horizons.length;
    var recencySum = 0.0;
    var recencyCount = 0;
    for (final horizon in horizons) {
      final last = horizon.lastExpanded;
      if (last == null) {
        continue;
      }
      final minutes = DateTime.now().difference(last).inMinutes;
      final freshness = (1 - (minutes / 180).clamp(0, 1)).clamp(0, 1);
      recencySum += freshness;
      recencyCount++;
    }
    final recencyAvg = recencyCount == 0 ? 0.25 : recencySum / recencyCount;
    return (intensityAvg * 0.55 + coherenceAvg * 0.3 + recencyAvg * 0.15)
        .clamp(0, 1);
  }

  double _calculateAuroraResonance(List<String> horizonIds) {
    if (horizonIds.isEmpty) {
      return 0;
    }
    final horizons = <ExperienceHorizon>[];
    for (final horizonId in horizonIds) {
      try {
        horizons.add(_horizons.firstWhere((entry) => entry.id == horizonId));
      } catch (_) {
        continue;
      }
    }
    if (horizons.isEmpty) {
      return 0;
    }
    final constellationLookup =
        {for (final entry in _constellations) entry.id: entry};
    final orbitLookup = {for (final orbit in _orbits) orbit.id: orbit};
    final intensityAvg = horizons
            .map((entry) => entry.intensity(constellationLookup, orbitLookup))
            .fold<double>(0, (value, element) => value + element) /
        horizons.length;
    final coherenceAvg = horizons
            .map((entry) => entry.coherence)
            .fold<double>(0, (value, element) => value + element) /
        horizons.length;
    final moodSpread = horizons
        .expand((entry) => entry.moodHints)
        .toSet()
        .length;
    final spreadScore = horizons.isEmpty ? 0 : (moodSpread / 4).clamp(0, 1);
    return (intensityAvg * 0.5 + coherenceAvg * 0.35 + spreadScore * 0.15)
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

  SceneMood _resolveAuroraMood(ExperienceAurora aurora) {
    if (aurora.moodHints.isNotEmpty) {
      return aurora.moodHints.first;
    }
    final moodCounts = <SceneMood, int>{};
    for (final horizonId in aurora.horizonIds) {
      ExperienceHorizon? horizon;
      try {
        horizon = _horizons.firstWhere((entry) => entry.id == horizonId);
      } catch (_) {
        horizon = null;
      }
      if (horizon == null) {
        continue;
      }
      final hints = horizon.moodHints.isEmpty
          ? <SceneMood>[_resolveHorizonMood(horizon)]
          : horizon.moodHints;
      for (final mood in hints) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }
    if (moodCounts.isEmpty) {
      return SceneMood.serene;
    }
    return moodCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  String _resolveAuroraBlueprintFallback(ExperienceAurora aurora) {
    for (final horizonId in aurora.horizonIds) {
      ExperienceHorizon? horizon;
      try {
        horizon = _horizons.firstWhere((entry) => entry.id == horizonId);
      } catch (_) {
        horizon = null;
      }
      if (horizon == null) {
        continue;
      }
      if (horizon.suggestedBlueprintId != null) {
        return horizon.suggestedBlueprintId!;
      }
      return _resolveHorizonBlueprintFallback(horizon);
    }
    if (_blueprints.isNotEmpty) {
      return _blueprints.first.id;
    }
    return 'bp_serenity';
  }

  String? _suggestAuroraBlueprint(List<String> horizonIds) {
    final counts = <String, double>{};
    for (final horizonId in horizonIds) {
      ExperienceHorizon? horizon;
      try {
        horizon = _horizons.firstWhere((entry) => entry.id == horizonId);
      } catch (_) {
        horizon = null;
      }
      if (horizon == null) {
        continue;
      }
      final suggestion = horizon.suggestedBlueprintId ??
          _suggestHorizonBlueprint(horizon.constellationIds);
      if (suggestion != null) {
        counts[suggestion] = (counts[suggestion] ?? 0) + 1.2;
      }
      for (final constellationId in horizon.constellationIds) {
        try {
          final constellation =
              _constellations.firstWhere((entry) => entry.id == constellationId);
          for (final blueprintId in constellation.blueprintIds) {
            counts[blueprintId] = (counts[blueprintId] ?? 0) + 0.6;
          }
        } catch (_) {
          continue;
        }
      }
    }
    if (counts.isEmpty) {
      return null;
    }
    String? bestId;
    var bestScore = -1.0;
    counts.forEach((id, baseScore) {
      final blueprint = findById(id);
      if (blueprint == null) {
        return;
      }
      final completion = _calculateBlueprintCompletion(blueprint);
      final focusBonus = _activeFocus?.blueprintId == id ? 0.25 : 0;
      final pinnedBonus = _pinned?.id == id ? 0.2 : 0;
      final score = baseScore + completion + focusBonus + pinnedBonus;
      if (score > bestScore) {
        bestScore = score;
        bestId = id;
      }
    });
    return bestId;
  }

  void _syncNebulas({bool persist = true}) {
    if (_nebulas.isEmpty) {
      return;
    }
    var changed = false;
    for (var i = 0; i < _nebulas.length; i++) {
      final base = _nebulas[i];
      final pulseItems = _collectNebulaPulseItems(base.auroraIds);
      final luminosity = _calculateNebulaLuminosity(base.auroraIds);
      final cohesion = _calculateNebulaCohesion(base.auroraIds);
      final suggestion = _suggestNebulaBlueprint(base.auroraIds);
      final pulseChanged = !_listMatches(base.pulseItemIds, pulseItems);
      final suggestionChanged = base.spotlightBlueprintId != suggestion;
      if (pulseChanged ||
          (luminosity - base.luminosity).abs() > 0.001 ||
          (cohesion - base.cohesion).abs() > 0.001 ||
          suggestionChanged) {
        final updated = ExperienceNebula(
          id: base.id,
          title: base.title,
          auroraIds: base.auroraIds,
          pulseItemIds: pulseItems,
          spectrumHints: base.spectrumHints,
          luminosity: luminosity,
          cohesion: cohesion,
          lastSurge: base.lastSurge,
          spotlightBlueprintId: suggestion ?? base.spotlightBlueprintId,
        );
        _nebulas[i] = updated;
        if (_activeNebula?.id == updated.id) {
          _activeNebula = updated;
        }
        changed = true;
      }
    }
    if (persist && changed) {
      _persistNebulas();
    }
    _syncNovas(persist: persist);
  }

  void _syncNovas({bool persist = true}) {
    if (_novas.isEmpty) {
      if (persist) {
        _persistNovas();
      }
      return;
    }
    var changed = false;
    for (var i = 0; i < _novas.length; i++) {
      final base = _novas[i];
      final catalyst = _collectNovaCatalystItems(base.nebulaIds);
      final intensity = _calculateNovaIntensity(base.nebulaIds);
      final stability = _calculateNovaStability(base.nebulaIds);
      final featured = _suggestNovaNebula(base.nebulaIds);
      final catalystChanged = !_listMatches(base.catalystItemIds, catalyst);
      final featuredChanged = featured != null && featured != base.featuredNebulaId;
      if (catalystChanged ||
          (intensity - base.intensity).abs() > 0.001 ||
          (stability - base.stability).abs() > 0.001 ||
          featuredChanged) {
        final updated = ExperienceNova(
          id: base.id,
          title: base.title,
          nebulaIds: base.nebulaIds,
          catalystItemIds: catalyst,
          sequenceHints: base.sequenceHints,
          intensity: intensity,
          stability: stability,
          lastIgnition: base.lastIgnition,
          featuredNebulaId: featured ?? base.featuredNebulaId,
        );
        _novas[i] = updated;
        if (_activeNova?.id == updated.id) {
          _activeNova = updated;
        }
        changed = true;
      }
    }
    if (persist && changed) {
      _persistNovas();
    }
  }

  void _syncAuroras({bool persist = true}) {
    if (_auroras.isEmpty) {
      return;
    }
    var changed = false;
    for (var i = 0; i < _auroras.length; i++) {
      final base = _auroras[i];
      final highlights = _collectAuroraHighlights(base.horizonIds);
      final radiance = _calculateAuroraRadiance(base.horizonIds);
      final resonance = _calculateAuroraResonance(base.horizonIds);
      final suggestion = _suggestAuroraBlueprint(base.horizonIds);
      final highlightChanged = !_listMatches(base.highlightItemIds, highlights);
      if (highlightChanged ||
          (radiance - base.radiance).abs() > 0.001 ||
          (resonance - base.resonance).abs() > 0.001 ||
          base.suggestedBlueprintId != suggestion) {
        final updated = ExperienceAurora(
          id: base.id,
          title: base.title,
          horizonIds: base.horizonIds,
          moodHints: base.moodHints,
          highlightItemIds: highlights,
          radiance: radiance,
          resonance: resonance,
          lastGlide: base.lastGlide,
          suggestedBlueprintId: suggestion,
        );
        _auroras[i] = updated;
        if (_activeAurora?.id == updated.id) {
          _activeAurora = updated;
        }
        changed = true;
      }
    }
    if (persist && changed) {
      _persistAuroras();
    }
    _syncNebulas(persist: persist);
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
    _auroraTimer?.cancel();
    _nebulaTimer?.cancel();
    _novaTimer?.cancel();
    _catalogController.removeListener(_catalogListener);
    _showroomController.removeListener(_showroomListener);
    _signalController.close();
    super.dispose();
  }
}
