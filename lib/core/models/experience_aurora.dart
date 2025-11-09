import 'dart:convert';

import 'experience_constellation.dart';
import 'experience_horizon.dart';
import 'experience_orbit.dart';
import 'showroom_scene.dart';

class ExperienceAurora {
  ExperienceAurora({
    required this.id,
    required this.title,
    required this.horizonIds,
    required this.moodHints,
    required this.highlightItemIds,
    this.radiance = 0,
    this.resonance = 0,
    this.lastGlide,
    this.suggestedBlueprintId,
  });

  final String id;
  final String title;
  final List<String> horizonIds;
  final List<SceneMood> moodHints;
  final List<String> highlightItemIds;
  final double radiance;
  final double resonance;
  final DateTime? lastGlide;
  final String? suggestedBlueprintId;

  double glow(
    Map<String, ExperienceHorizon> horizonLookup,
    Map<String, ExperienceConstellation> constellationLookup,
    Map<String, ExperienceOrbit> orbitLookup,
  ) {
    if (horizonIds.isEmpty) {
      return radiance.clamp(0, 1);
    }
    final intensities = horizonIds
        .map((id) => horizonLookup[id]?.intensity(constellationLookup, orbitLookup) ?? 0)
        .toList();
    if (intensities.isEmpty) {
      return radiance.clamp(0, 1);
    }
    final average =
        intensities.reduce((value, element) => value + element) / intensities.length;
    return (radiance * 0.35 + average * 0.65).clamp(0, 1);
  }

  ExperienceAurora copyWith({
    List<String>? highlightItemIds,
    double? radiance,
    double? resonance,
    DateTime? lastGlide,
    String? suggestedBlueprintId,
  }) {
    return ExperienceAurora(
      id: id,
      title: title,
      horizonIds: horizonIds,
      moodHints: moodHints,
      highlightItemIds: highlightItemIds ?? this.highlightItemIds,
      radiance: radiance ?? this.radiance,
      resonance: resonance ?? this.resonance,
      lastGlide: lastGlide ?? this.lastGlide,
      suggestedBlueprintId: suggestedBlueprintId ?? this.suggestedBlueprintId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'horizonIds': horizonIds,
        'moodHints': moodHints.map((mood) => mood.name).toList(),
        'highlightItemIds': highlightItemIds,
        'radiance': radiance,
        'resonance': resonance,
        'lastGlide': lastGlide?.toIso8601String(),
        'suggestedBlueprintId': suggestedBlueprintId,
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceAurora.fromJson(Map<String, dynamic> json) {
    return ExperienceAurora(
      id: json['id'] as String,
      title: json['title'] as String,
      horizonIds: (json['horizonIds'] as List<dynamic>).cast<String>(),
      moodHints: (json['moodHints'] as List<dynamic>)
          .map((entry) => SceneMood.values.firstWhere(
                (value) => value.name == entry,
                orElse: () => SceneMood.serene,
              ))
          .toList(),
      highlightItemIds: (json['highlightItemIds'] as List<dynamic>).cast<String>(),
      radiance: (json['radiance'] as num?)?.toDouble() ?? 0,
      resonance: (json['resonance'] as num?)?.toDouble() ?? 0,
      lastGlide: json['lastGlide'] == null
          ? null
          : DateTime.parse(json['lastGlide'] as String),
      suggestedBlueprintId: json['suggestedBlueprintId'] as String?,
    );
  }

  factory ExperienceAurora.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceAurora.fromJson(map);
  }
}
