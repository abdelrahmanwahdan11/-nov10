import 'dart:convert';

import 'showroom_scene.dart';

class ExperienceSingularity {
  ExperienceSingularity({
    required this.id,
    required this.title,
    required this.quasarIds,
    required this.coreItemIds,
    required this.anomalyHints,
    this.gravity = 0,
    this.convergence = 0,
    this.equilibrium = 0,
    this.lastCollapse,
    this.featuredQuasarId,
  });

  final String id;
  final String title;
  final List<String> quasarIds;
  final List<String> coreItemIds;
  final List<SceneMood> anomalyHints;
  final double gravity;
  final double convergence;
  final double equilibrium;
  final DateTime? lastCollapse;
  final String? featuredQuasarId;

  ExperienceSingularity copyWith({
    List<String>? coreItemIds,
    double? gravity,
    double? convergence,
    double? equilibrium,
    DateTime? lastCollapse,
    String? featuredQuasarId,
  }) {
    return ExperienceSingularity(
      id: id,
      title: title,
      quasarIds: quasarIds,
      coreItemIds: coreItemIds ?? this.coreItemIds,
      anomalyHints: anomalyHints,
      gravity: gravity ?? this.gravity,
      convergence: convergence ?? this.convergence,
      equilibrium: equilibrium ?? this.equilibrium,
      lastCollapse: lastCollapse ?? this.lastCollapse,
      featuredQuasarId: featuredQuasarId ?? this.featuredQuasarId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'quasarIds': quasarIds,
        'coreItemIds': coreItemIds,
        'anomalyHints': anomalyHints.map((mood) => mood.name).toList(),
        'gravity': gravity,
        'convergence': convergence,
        'equilibrium': equilibrium,
        'lastCollapse': lastCollapse?.toIso8601String(),
        'featuredQuasarId': featuredQuasarId,
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceSingularity.fromJson(Map<String, dynamic> json) {
    return ExperienceSingularity(
      id: json['id'] as String,
      title: json['title'] as String,
      quasarIds: (json['quasarIds'] as List<dynamic>).cast<String>(),
      coreItemIds: (json['coreItemIds'] as List<dynamic>).cast<String>(),
      anomalyHints: (json['anomalyHints'] as List<dynamic>)
          .map(
            (entry) => SceneMood.values.firstWhere(
              (value) => value.name == entry,
              orElse: () => SceneMood.serene,
            ),
          )
          .toList(),
      gravity: (json['gravity'] as num?)?.toDouble() ?? 0,
      convergence: (json['convergence'] as num?)?.toDouble() ?? 0,
      equilibrium: (json['equilibrium'] as num?)?.toDouble() ?? 0,
      lastCollapse:
          json['lastCollapse'] == null ? null : DateTime.parse(json['lastCollapse'] as String),
      featuredQuasarId: json['featuredQuasarId'] as String?,
    );
  }

  factory ExperienceSingularity.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceSingularity.fromJson(map);
  }
}
