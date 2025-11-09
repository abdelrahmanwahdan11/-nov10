import 'dart:convert';

import 'experience_constellation.dart';
import 'experience_orbit.dart';
import 'showroom_scene.dart';

class ExperienceHorizon {
  ExperienceHorizon({
    required this.id,
    required this.title,
    required this.constellationIds,
    required this.moodHints,
    required this.passageItemIds,
    this.coherence = 0,
    this.lastExpanded,
    this.suggestedBlueprintId,
  });

  final String id;
  final String title;
  final List<String> constellationIds;
  final List<SceneMood> moodHints;
  final List<String> passageItemIds;
  final double coherence;
  final DateTime? lastExpanded;
  final String? suggestedBlueprintId;

  double intensity(
    Map<String, ExperienceConstellation> constellationLookup,
    Map<String, ExperienceOrbit> orbitLookup,
  ) {
    if (constellationIds.isEmpty) {
      return coherence.clamp(0, 1);
    }
    final energyValues = constellationIds
        .map((id) => constellationLookup[id]?.energy(orbitLookup) ?? 0)
        .toList();
    if (energyValues.isEmpty) {
      return coherence.clamp(0, 1);
    }
    final averageEnergy =
        energyValues.reduce((value, element) => value + element) /
            energyValues.length;
    return (coherence * 0.4 + averageEnergy * 0.6).clamp(0, 1);
  }

  ExperienceHorizon copyWith({
    List<String>? passageItemIds,
    double? coherence,
    DateTime? lastExpanded,
    String? suggestedBlueprintId,
  }) {
    return ExperienceHorizon(
      id: id,
      title: title,
      constellationIds: constellationIds,
      moodHints: moodHints,
      passageItemIds: passageItemIds ?? this.passageItemIds,
      coherence: coherence ?? this.coherence,
      lastExpanded: lastExpanded ?? this.lastExpanded,
      suggestedBlueprintId: suggestedBlueprintId ?? this.suggestedBlueprintId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'constellationIds': constellationIds,
        'moodHints': moodHints.map((mood) => mood.name).toList(),
        'passageItemIds': passageItemIds,
        'coherence': coherence,
        'lastExpanded': lastExpanded?.toIso8601String(),
        'suggestedBlueprintId': suggestedBlueprintId,
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceHorizon.fromJson(Map<String, dynamic> json) {
    return ExperienceHorizon(
      id: json['id'] as String,
      title: json['title'] as String,
      constellationIds:
          (json['constellationIds'] as List<dynamic>).cast<String>(),
      moodHints: (json['moodHints'] as List<dynamic>)
          .map((entry) => SceneMood.values.firstWhere(
                (value) => value.name == entry,
                orElse: () => SceneMood.serene,
              ))
          .toList(),
      passageItemIds:
          (json['passageItemIds'] as List<dynamic>).cast<String>(),
      coherence: (json['coherence'] as num?)?.toDouble() ?? 0,
      lastExpanded: json['lastExpanded'] == null
          ? null
          : DateTime.parse(json['lastExpanded'] as String),
      suggestedBlueprintId: json['suggestedBlueprintId'] as String?,
    );
  }

  factory ExperienceHorizon.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceHorizon.fromJson(map);
  }
}
