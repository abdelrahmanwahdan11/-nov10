import 'showroom_scene.dart';

class ExperiencePhase {
  const ExperiencePhase({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    this.focusTags = const <String>[],
  });

  final String id;
  final String title;
  final String description;
  final int estimatedMinutes;
  final List<String> focusTags;
}

class ExperienceBlueprint {
  const ExperienceBlueprint({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.focusMood,
    required this.primaryImage,
    required this.relatedItemIds,
    required this.phases,
    this.highlightedInsights = const <String>[],
  });

  final String id;
  final String title;
  final String subtitle;
  final SceneMood focusMood;
  final String primaryImage;
  final List<String> relatedItemIds;
  final List<ExperiencePhase> phases;
  final List<String> highlightedInsights;

  double progress(double Function(String key) phaseProgressGetter) {
    if (phases.isEmpty) {
      return 0;
    }
    final total = phases.fold<double>(0, (value, phase) {
      return value + phaseProgressGetter(_phaseKey(phase.id));
    });
    return (total / phases.length).clamp(0, 1);
  }

  String _phaseKey(String phaseId) => '$id::$phaseId';

  Iterable<String> get phaseKeys =>
      phases.map((phase) => _phaseKey(phase.id));
}

class ExperienceSignal {
  ExperienceSignal({
    required this.id,
    required this.headline,
    required this.body,
    required this.generatedAt,
    required this.relatedItemIds,
    required this.blueprintId,
  });

  final String id;
  final String headline;
  final String body;
  final DateTime generatedAt;
  final List<String> relatedItemIds;
  final String blueprintId;
}

extension ExperiencePhaseKey on ExperienceBlueprint {
  String resolvePhaseKey(String phaseId) => '$id::$phaseId';
}
