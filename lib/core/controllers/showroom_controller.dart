import 'dart:async';

import 'package:flutter/material.dart';

import '../models/item.dart';
import '../models/showroom_scene.dart';
import '../services/app_preferences.dart';
import 'catalog_controller.dart';

class ShowroomController extends ChangeNotifier {
  ShowroomController({
    required CatalogController catalogController,
    required AppPreferences preferences,
  })  : _catalogController = catalogController,
        _preferences = preferences {
    _catalogListener = () {
      notifyListeners();
    };
    _catalogController.addListener(_catalogListener);
    _seedScenes();
    _restoreState();
  }

  final CatalogController _catalogController;
  final AppPreferences _preferences;
  late final VoidCallback _catalogListener;
  final List<ShowroomScene> _scenes = <ShowroomScene>[];
  SceneMood? _activeMood;
  int _currentIndex = 0;
  Timer? _autoTimer;

  List<ShowroomScene> get allScenes => List.unmodifiable(_scenes);
  SceneMood? get activeMood => _activeMood;
  int get currentIndex => _currentIndex.clamp(0, scenes.isEmpty ? 0 : scenes.length - 1);
  bool get isAutoCycling => _autoTimer?.isActive ?? false;

  List<ShowroomScene> get scenes {
    if (_activeMood == null) {
      return List.unmodifiable(_scenes);
    }
    return _scenes.where((scene) => scene.mood == _activeMood).toList();
  }

  List<ShowroomScene> get recommendedScenes {
    if (_catalogController.favoriteIds.isEmpty) {
      return scenes;
    }
    return scenes
        .where(
          (scene) => scene.itemIds
              .any((id) => _catalogController.favoriteIds.contains(id)),
        )
        .toList();
  }

  void setMood(SceneMood? mood) {
    _activeMood = mood;
    unawaited(_preferences.setShowroomMood(mood?.storageKey));
    if (_currentIndex >= scenes.length) {
      _currentIndex = 0;
    }
    _scheduleAutoCycle();
    notifyListeners();
  }

  void setIndex(int index) {
    if (scenes.isEmpty) return;
    final clamped = index.clamp(0, scenes.length - 1);
    if (clamped == _currentIndex) return;
    _currentIndex = clamped;
    final scene = scenes[_currentIndex];
    unawaited(_preferences.setShowroomScene(scene.id));
    notifyListeners();
  }

  void toggleAutoCycle() {
    if (_autoTimer?.isActive ?? false) {
      _autoTimer?.cancel();
    } else {
      _scheduleAutoCycle();
    }
    notifyListeners();
  }

  void _scheduleAutoCycle() {
    _autoTimer?.cancel();
    if (scenes.isEmpty) return;
    final scene = scenes[_currentIndex % scenes.length];
    _autoTimer = Timer(scene.displayDuration, () {
      final next = (_currentIndex + 1) % scenes.length;
      setIndex(next);
      _scheduleAutoCycle();
    });
  }

  List<CatalogItem> resolveItems(ShowroomScene scene) {
    return scene.itemIds
        .map((id) => _catalogController.findById(id))
        .whereType<CatalogItem>()
        .toList();
  }

  void _restoreState() {
    final moodKey = _preferences.getShowroomMood();
    if (moodKey != null) {
      for (final mood in SceneMood.values) {
        if (mood.storageKey == moodKey) {
          _activeMood = mood;
          break;
        }
      }
    }
    final storedScene = _preferences.getShowroomScene();
    if (storedScene != null) {
      final index = scenes.indexWhere((scene) => scene.id == storedScene);
      if (index != -1) {
        _currentIndex = index;
      }
    }
    _scheduleAutoCycle();
  }

  void _seedScenes() {
    _scenes
      ..clear()
      ..addAll([
        ShowroomScene(
          id: 'scene_aurora',
          mood: SceneMood.serene,
          title: 'Aurora Retreat',
          subtitle: 'ألوان فجرية هادئة توازن بين الراحة والضوء الطبيعي',
          story:
              'تجربة مهدئة مستوحاة من الطبيعة تجمع بين الألوان الناعمة والخامات العضوية لتكوين بيئة استرخاء متكاملة.',
          heroImage: 'https://images.unsplash.com/photo-1505691723518-36a5ac3be353',
          itemIds: const ['item_1', 'item_5', 'item_7'],
          highlights: const [
            'إضاءة خافتة قابلة للتخصيص',
            'خامات طبيعية معاد تدويرها',
            'نظام عزل صوتي لإحساس بالهدوء',
          ],
          displayDuration: const Duration(seconds: 10),
        ),
        ShowroomScene(
          id: 'scene_pulse',
          mood: SceneMood.vibrant,
          title: 'Pulse Gallery',
          subtitle: 'مساحة نابضة بالحياة مليئة بالحركة والألوان الجريئة',
          story:
              'تعتمد المساحة على تناغم بين التكنولوجيا والعناصر الفنية لتقديم عرض مرئي غني وحيوي مع انتقالات ضوئية ديناميكية.',
          heroImage: 'https://images.unsplash.com/photo-1505691938895-1758d7feb511',
          itemIds: const ['item_3', 'item_9', 'item_12'],
          highlights: const [
            'جدران تفاعلية للاستعراض السريع',
            'مقاعد مرنة قابلة لإعادة التشكيل',
            'مؤثرات بصرية ثلاثية الأبعاد عند استعراض المنتجات',
          ],
        ),
        ShowroomScene(
          id: 'scene_quantum',
          mood: SceneMood.futuristic,
          title: 'Quantum Loft',
          subtitle: 'بساطة مستقبلية مع طبقات من الإضاءة الذكية',
          story:
              'مركز إلهام لعشاق التقنية مع خطوط هندسية حادة وأنظمة إضاءة متجاوبة تحاكي الحركة.',
          heroImage: 'https://images.unsplash.com/photo-1524758631624-e2822e304c36',
          itemIds: const ['item_15', 'item_18', 'item_22'],
          highlights: const [
            'مخطط ألوان ديناميكي يعتمد على وقت اليوم',
            'أسطح ذكية تتغير حسب الاستخدام',
            'إحصائيات مباشرة عن التفاعل مع كل عنصر',
          ],
          displayDuration: const Duration(seconds: 12),
        ),
        ShowroomScene(
          id: 'scene_tierra',
          mood: SceneMood.earthy,
          title: 'Tierra Atelier',
          subtitle: 'مساحة فنية دافئة مستوحاة من خامات الأرض',
          story:
              'تجمع هذه المحطة بين الحرفية التقليدية والتصميم المعاصر مع مواد خام متدرجة الدرجات لإحساس طبيعي.',
          heroImage: 'https://images.unsplash.com/photo-1487017159836-4e23ece2e4cf',
          itemIds: const ['item_2', 'item_6', 'item_27'],
          highlights: const [
            'مواد حرفية محلية بملمس غني',
            'تباين ضوئي يحاكي ضوء الشمس الطبيعي',
            'نظام توصية يقترح قطعاً مكملة تلقائياً',
          ],
        ),
      ]);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _catalogController.removeListener(_catalogListener);
    super.dispose();
  }
}
