import 'dart:convert';

import 'experience_orbit.dart';
import 'showroom_scene.dart';

class ExperienceConstellation {
  ExperienceConstellation({
    required this.id,
    required this.title,
    required this.blueprintIds,
    required this.moods,
    required this.anchorItemIds,
    this.synergy = 0,
    this.lastAligned,
  });

  final String id;
  final String title;
  final List<String> blueprintIds;
  final List<SceneMood> moods;
  final List<String> anchorItemIds;
  final double synergy;
  final DateTime? lastAligned;

  double energy(Map<String, ExperienceOrbit> orbitLookup) {
    if (blueprintIds.isEmpty) {
      return synergy.clamp(0, 1);
    }
    final orbitEnergy = blueprintIds
        .map((id) => orbitLookup['orbit_$id']?.intensity ?? 0)
        .fold<double>(0, (value, element) => value + element) /
        blueprintIds.length;
    final freshness = lastAligned == null
        ? 0.0
        : (1 -
                (DateTime.now().difference(lastAligned!).inMinutes / 90)
                    .clamp(0, 1))
            .clamp(0, 1);
    return (synergy * 0.45 + orbitEnergy * 0.4 + freshness * 0.15)
        .clamp(0, 1);
  }

  ExperienceConstellation copyWith({
    List<String>? anchorItemIds,
    double? synergy,
    DateTime? lastAligned,
  }) {
    return ExperienceConstellation(
      id: id,
      title: title,
      blueprintIds: blueprintIds,
      moods: moods,
      anchorItemIds: anchorItemIds ?? this.anchorItemIds,
      synergy: synergy ?? this.synergy,
      lastAligned: lastAligned ?? this.lastAligned,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'blueprintIds': blueprintIds,
        'moods': moods.map((mood) => mood.name).toList(),
        'anchorItemIds': anchorItemIds,
        'synergy': synergy,
        'lastAligned': lastAligned?.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceConstellation.fromJson(Map<String, dynamic> json) {
    return ExperienceConstellation(
      id: json['id'] as String,
      title: json['title'] as String,
      blueprintIds: (json['blueprintIds'] as List<dynamic>).cast<String>(),
      moods: (json['moods'] as List<dynamic>)
          .map((entry) => SceneMood.values.firstWhere(
                (value) => value.name == entry,
                orElse: () => SceneMood.serene,
              ))
          .toList(),
      anchorItemIds:
          (json['anchorItemIds'] as List<dynamic>).cast<String>(),
      synergy: (json['synergy'] as num?)?.toDouble() ?? 0,
      lastAligned: json['lastAligned'] == null
          ? null
          : DateTime.parse(json['lastAligned'] as String),
    );
  }

  factory ExperienceConstellation.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceConstellation.fromJson(map);
  }
}
