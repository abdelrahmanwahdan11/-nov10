import 'dart:convert';

import 'experience_aurora.dart';
import 'experience_constellation.dart';
import 'experience_horizon.dart';
import 'experience_orbit.dart';
import 'showroom_scene.dart';

class ExperienceNebula {
  ExperienceNebula({
    required this.id,
    required this.title,
    required this.auroraIds,
    required this.pulseItemIds,
    required this.spectrumHints,
    this.luminosity = 0,
    this.cohesion = 0,
    this.lastSurge,
    this.spotlightBlueprintId,
  });

  final String id;
  final String title;
  final List<String> auroraIds;
  final List<String> pulseItemIds;
  final List<SceneMood> spectrumHints;
  final double luminosity;
  final double cohesion;
  final DateTime? lastSurge;
  final String? spotlightBlueprintId;

  double clarity(
    Map<String, ExperienceAurora> auroraLookup,
    Map<String, ExperienceHorizon> horizonLookup,
    Map<String, ExperienceConstellation> constellationLookup,
    Map<String, ExperienceOrbit> orbitLookup,
  ) {
    if (auroraIds.isEmpty) {
      return ((luminosity * 0.7) + (cohesion * 0.3)).clamp(0, 1);
    }
    final values = auroraIds
        .map((id) => auroraLookup[id])
        .whereType<ExperienceAurora>()
        .map((aurora) => aurora.glow(horizonLookup, constellationLookup, orbitLookup))
        .toList();
    if (values.isEmpty) {
      return ((luminosity * 0.7) + (cohesion * 0.3)).clamp(0, 1);
    }
    final average = values.reduce((value, element) => value + element) / values.length;
    return ((average * 0.6) + (cohesion * 0.4)).clamp(0, 1);
  }

  ExperienceNebula copyWith({
    List<String>? pulseItemIds,
    double? luminosity,
    double? cohesion,
    DateTime? lastSurge,
    String? spotlightBlueprintId,
  }) {
    return ExperienceNebula(
      id: id,
      title: title,
      auroraIds: auroraIds,
      pulseItemIds: pulseItemIds ?? this.pulseItemIds,
      spectrumHints: spectrumHints,
      luminosity: luminosity ?? this.luminosity,
      cohesion: cohesion ?? this.cohesion,
      lastSurge: lastSurge ?? this.lastSurge,
      spotlightBlueprintId: spotlightBlueprintId ?? this.spotlightBlueprintId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'auroraIds': auroraIds,
        'pulseItemIds': pulseItemIds,
        'spectrumHints': spectrumHints.map((mood) => mood.name).toList(),
        'luminosity': luminosity,
        'cohesion': cohesion,
        'lastSurge': lastSurge?.toIso8601String(),
        'spotlightBlueprintId': spotlightBlueprintId,
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceNebula.fromJson(Map<String, dynamic> json) {
    return ExperienceNebula(
      id: json['id'] as String,
      title: json['title'] as String,
      auroraIds: (json['auroraIds'] as List<dynamic>).cast<String>(),
      pulseItemIds: (json['pulseItemIds'] as List<dynamic>).cast<String>(),
      spectrumHints: (json['spectrumHints'] as List<dynamic>)
          .map((entry) => SceneMood.values.firstWhere(
                (value) => value.name == entry,
                orElse: () => SceneMood.serene,
              ))
          .toList(),
      luminosity: (json['luminosity'] as num?)?.toDouble() ?? 0,
      cohesion: (json['cohesion'] as num?)?.toDouble() ?? 0,
      lastSurge:
          json['lastSurge'] == null ? null : DateTime.parse(json['lastSurge'] as String),
      spotlightBlueprintId: json['spotlightBlueprintId'] as String?,
    );
  }

  factory ExperienceNebula.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceNebula.fromJson(map);
  }
}
