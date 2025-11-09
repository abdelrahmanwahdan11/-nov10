import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/experience_blueprint.dart';
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
      notifyListeners();
    };
    _showroomListener = notifyListeners;
    _catalogController.addListener(_catalogListener);
    _showroomController.addListener(_showroomListener);
    _seedBlueprints();
    _restoreState();
    _schedulePulse();
    _scheduleOrbitCycle();
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

  List<ExperienceBlueprint> get blueprints => List.unmodifiable(_blueprints);
  ExperienceBlueprint? get pinnedBlueprint => _pinned;
  List<ExperienceSignal> get signals => List.unmodifiable(_signals);
  Stream<ExperienceSignal> get pulseStream => _signalController.stream;
  List<ExperienceMoment> get chronicle => List.unmodifiable(_chronicle);
  ExperienceFocus? get activeFocus => _activeFocus;
  List<ExperienceOrbit> get orbits => List.unmodifiable(_orbits);
  ExperienceOrbit? get activeOrbit => _activeOrbit;

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
    _initializeOrbits();
    _scheduleOrbitCycle();
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

  void _persistOrbits() {
    unawaited(
      _preferences.setExperienceOrbits(
        _orbits.map((orbit) => orbit.encode()).toList(),
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
    _catalogController.removeListener(_catalogListener);
    _showroomController.removeListener(_showroomListener);
    _signalController.close();
    super.dispose();
  }
}
