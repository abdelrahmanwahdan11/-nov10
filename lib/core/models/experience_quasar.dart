import 'dart:convert';

import 'showroom_scene.dart';

class ExperienceQuasar {
  ExperienceQuasar({
    required this.id,
    required this.title,
    required this.novaIds,
    required this.beaconItemIds,
    required this.prismHints,
    this.flare = 0,
    this.steadiness = 0,
    this.flux = 0,
    this.lastBeacon,
    this.featuredNovaId,
  });

  final String id;
  final String title;
  final List<String> novaIds;
  final List<String> beaconItemIds;
  final List<SceneMood> prismHints;
  final double flare;
  final double steadiness;
  final double flux;
  final DateTime? lastBeacon;
  final String? featuredNovaId;

  ExperienceQuasar copyWith({
    List<String>? beaconItemIds,
    double? flare,
    double? steadiness,
    double? flux,
    DateTime? lastBeacon,
    String? featuredNovaId,
  }) {
    return ExperienceQuasar(
      id: id,
      title: title,
      novaIds: novaIds,
      beaconItemIds: beaconItemIds ?? this.beaconItemIds,
      prismHints: prismHints,
      flare: flare ?? this.flare,
      steadiness: steadiness ?? this.steadiness,
      flux: flux ?? this.flux,
      lastBeacon: lastBeacon ?? this.lastBeacon,
      featuredNovaId: featuredNovaId ?? this.featuredNovaId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'novaIds': novaIds,
        'beaconItemIds': beaconItemIds,
        'prismHints': prismHints.map((mood) => mood.name).toList(),
        'flare': flare,
        'steadiness': steadiness,
        'flux': flux,
        'lastBeacon': lastBeacon?.toIso8601String(),
        'featuredNovaId': featuredNovaId,
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceQuasar.fromJson(Map<String, dynamic> json) {
    return ExperienceQuasar(
      id: json['id'] as String,
      title: json['title'] as String,
      novaIds: (json['novaIds'] as List<dynamic>).cast<String>(),
      beaconItemIds: (json['beaconItemIds'] as List<dynamic>).cast<String>(),
      prismHints: (json['prismHints'] as List<dynamic>)
          .map(
            (entry) => SceneMood.values.firstWhere(
              (value) => value.name == entry,
              orElse: () => SceneMood.serene,
            ),
          )
          .toList(),
      flare: (json['flare'] as num?)?.toDouble() ?? 0,
      steadiness: (json['steadiness'] as num?)?.toDouble() ?? 0,
      flux: (json['flux'] as num?)?.toDouble() ?? 0,
      lastBeacon:
          json['lastBeacon'] == null ? null : DateTime.parse(json['lastBeacon'] as String),
      featuredNovaId: json['featuredNovaId'] as String?,
    );
  }

  factory ExperienceQuasar.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceQuasar.fromJson(map);
  }
}
