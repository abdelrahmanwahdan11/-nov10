import 'package:flutter/foundation.dart';

enum SceneMood { serene, vibrant, futuristic, earthy }

class ShowroomScene {
  ShowroomScene({
    required this.id,
    required this.mood,
    required this.title,
    required this.subtitle,
    required this.story,
    required this.heroImage,
    required this.itemIds,
    required this.highlights,
    this.displayDuration = const Duration(seconds: 8),
  });

  final String id;
  final SceneMood mood;
  final String title;
  final String subtitle;
  final String story;
  final String heroImage;
  final List<String> itemIds;
  final List<String> highlights;
  final Duration displayDuration;
}

extension SceneMoodName on SceneMood {
  String localizedLabel({required bool isArabic}) {
    switch (this) {
      case SceneMood.serene:
        return isArabic ? 'هادئ' : 'Serene';
      case SceneMood.vibrant:
        return isArabic ? 'نابض' : 'Vibrant';
      case SceneMood.futuristic:
        return isArabic ? 'مستقبلي' : 'Futuristic';
      case SceneMood.earthy:
        return isArabic ? 'ترابي' : 'Earthy';
    }
  }

  String get storageKey => describeEnum(this);
}
