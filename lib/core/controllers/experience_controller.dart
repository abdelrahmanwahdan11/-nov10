import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/experience_blueprint.dart';
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

  List<ExperienceBlueprint> get blueprints => List.unmodifiable(_blueprints);
  ExperienceBlueprint? get pinnedBlueprint => _pinned;
  List<ExperienceSignal> get signals => List.unmodifiable(_signals);
  Stream<ExperienceSignal> get pulseStream => _signalController.stream;

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

  void pinBlueprint(ExperienceBlueprint blueprint) {
    if (_pinned?.id == blueprint.id) {
      return;
    }
    _pinned = blueprint;
    unawaited(_preferences.setPinnedBlueprintId(blueprint.id));
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
    notifyListeners();
  }

  Future<void> refreshBlueprints() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _signals.clear();
    _phaseProgress.clear();
    final keys = _blueprints.expand((blueprint) => blueprint.phaseKeys);
    await _preferences.resetExperiencePhases(keys);
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
    notifyListeners();
  }

  void _restoreState() {
    final pinnedId = _preferences.getPinnedBlueprintId();
    if (pinnedId != null) {
      _pinned = findById(pinnedId);
    }
    for (final blueprint in _blueprints) {
      for (final key in blueprint.phaseKeys) {
        _getPhaseProgress(key);
      }
    }
    _emitPulse(force: true);
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
    _catalogController.removeListener(_catalogListener);
    _showroomController.removeListener(_showroomListener);
    _signalController.close();
    super.dispose();
  }
}
