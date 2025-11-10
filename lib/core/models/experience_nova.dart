import 'dart:convert';

import 'experience_aurora.dart';
import 'experience_constellation.dart';
import 'experience_horizon.dart';
import 'experience_nebula.dart';
import 'experience_orbit.dart';
import 'showroom_scene.dart';

class ExperienceNova {
  ExperienceNova({
    required this.id,
    required this.title,
    required this.nebulaIds,
    required this.catalystItemIds,
    required this.sequenceHints,
    this.intensity = 0,
    this.stability = 0,
    this.lastIgnition,
    this.featuredNebulaId,
  });

  final String id;
  final String title;
  final List<String> nebulaIds;
  final List<String> catalystItemIds;
  final List<SceneMood> sequenceHints;
  final double intensity;
  final double stability;
  final DateTime? lastIgnition;
  final String? featuredNebulaId;

  double brilliance(
    Map<String, ExperienceNebula> nebulaLookup,
    Map<String, ExperienceAurora> auroraLookup,
    Map<String, ExperienceHorizon> horizonLookup,
    Map<String, ExperienceConstellation> constellationLookup,
    Map<String, ExperienceOrbit> orbitLookup,
  ) {
    if (nebulaIds.isEmpty) {
      return ((intensity * 0.6) + (stability * 0.4)).clamp(0, 1);
    }
    final clarityValues = nebulaIds
        .map((id) => nebulaLookup[id])
        .whereType<ExperienceNebula>()
        .map(
          (nebula) => nebula.clarity(
            auroraLookup,
            horizonLookup,
            constellationLookup,
            orbitLookup,
          ),
        )
        .toList();
    if (clarityValues.isEmpty) {
      return ((intensity * 0.6) + (stability * 0.4)).clamp(0, 1);
    }
    final average =
        clarityValues.reduce((value, element) => value + element) / clarityValues.length;
    return ((average * 0.7) + (intensity * 0.3)).clamp(0, 1);
  }

  ExperienceNova copyWith({
    List<String>? catalystItemIds,
    double? intensity,
    double? stability,
    DateTime? lastIgnition,
    String? featuredNebulaId,
  }) {
    return ExperienceNova(
      id: id,
      title: title,
      nebulaIds: nebulaIds,
      catalystItemIds: catalystItemIds ?? this.catalystItemIds,
      sequenceHints: sequenceHints,
      intensity: intensity ?? this.intensity,
      stability: stability ?? this.stability,
      lastIgnition: lastIgnition ?? this.lastIgnition,
      featuredNebulaId: featuredNebulaId ?? this.featuredNebulaId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'nebulaIds': nebulaIds,
        'catalystItemIds': catalystItemIds,
        'sequenceHints': sequenceHints.map((mood) => mood.name).toList(),
        'intensity': intensity,
        'stability': stability,
        'lastIgnition': lastIgnition?.toIso8601String(),
        'featuredNebulaId': featuredNebulaId,
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceNova.fromJson(Map<String, dynamic> json) {
    return ExperienceNova(
      id: json['id'] as String,
      title: json['title'] as String,
      nebulaIds: (json['nebulaIds'] as List<dynamic>).cast<String>(),
      catalystItemIds: (json['catalystItemIds'] as List<dynamic>).cast<String>(),
      sequenceHints: (json['sequenceHints'] as List<dynamic>)
          .map(
            (entry) => SceneMood.values.firstWhere(
              (value) => value.name == entry,
              orElse: () => SceneMood.serene,
            ),
          )
          .toList(),
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0,
      stability: (json['stability'] as num?)?.toDouble() ?? 0,
      lastIgnition:
          json['lastIgnition'] == null ? null : DateTime.parse(json['lastIgnition'] as String),
      featuredNebulaId: json['featuredNebulaId'] as String?,
    );
  }

  factory ExperienceNova.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceNova.fromJson(map);
  }
}
