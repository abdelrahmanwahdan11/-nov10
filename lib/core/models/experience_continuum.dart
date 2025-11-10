import 'dart:convert';

import 'showroom_scene.dart';

class ExperienceContinuum {
  ExperienceContinuum({
    required this.id,
    required this.title,
    required this.singularityIds,
    required this.flowItemIds,
    required this.harmonyHints,
    this.density = 0,
    this.synergy = 0,
    this.stability = 0,
    this.lastFusion,
    this.featuredSingularityId,
  });

  final String id;
  final String title;
  final List<String> singularityIds;
  final List<String> flowItemIds;
  final List<SceneMood> harmonyHints;
  final double density;
  final double synergy;
  final double stability;
  final DateTime? lastFusion;
  final String? featuredSingularityId;

  ExperienceContinuum copyWith({
    List<String>? flowItemIds,
    double? density,
    double? synergy,
    double? stability,
    DateTime? lastFusion,
    String? featuredSingularityId,
  }) {
    return ExperienceContinuum(
      id: id,
      title: title,
      singularityIds: singularityIds,
      flowItemIds: flowItemIds ?? this.flowItemIds,
      harmonyHints: harmonyHints,
      density: density ?? this.density,
      synergy: synergy ?? this.synergy,
      stability: stability ?? this.stability,
      lastFusion: lastFusion ?? this.lastFusion,
      featuredSingularityId: featuredSingularityId ?? this.featuredSingularityId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'singularityIds': singularityIds,
        'flowItemIds': flowItemIds,
        'harmonyHints': harmonyHints.map((mood) => mood.name).toList(),
        'density': density,
        'synergy': synergy,
        'stability': stability,
        'lastFusion': lastFusion?.toIso8601String(),
        'featuredSingularityId': featuredSingularityId,
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceContinuum.fromJson(Map<String, dynamic> json) {
    return ExperienceContinuum(
      id: json['id'] as String,
      title: json['title'] as String,
      singularityIds: (json['singularityIds'] as List<dynamic>).cast<String>(),
      flowItemIds: (json['flowItemIds'] as List<dynamic>).cast<String>(),
      harmonyHints: (json['harmonyHints'] as List<dynamic>)
          .map(
            (entry) => SceneMood.values.firstWhere(
              (value) => value.name == entry,
              orElse: () => SceneMood.serene,
            ),
          )
          .toList(),
      density: (json['density'] as num?)?.toDouble() ?? 0,
      synergy: (json['synergy'] as num?)?.toDouble() ?? 0,
      stability: (json['stability'] as num?)?.toDouble() ?? 0,
      lastFusion:
          json['lastFusion'] == null ? null : DateTime.parse(json['lastFusion'] as String),
      featuredSingularityId: json['featuredSingularityId'] as String?,
    );
  }

  factory ExperienceContinuum.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceContinuum.fromJson(map);
  }
}
