import 'dart:convert';

import 'showroom_scene.dart';

class ExperienceOrbit {
  ExperienceOrbit({
    required this.id,
    required this.blueprintId,
    required this.title,
    required this.mood,
    required this.phaseIds,
    required this.highlightItemIds,
    this.pulseCount = 0,
    this.completion = 0,
    this.hasFocus = false,
    this.lastActivated,
  });

  final String id;
  final String blueprintId;
  final String title;
  final SceneMood mood;
  final List<String> phaseIds;
  final List<String> highlightItemIds;
  final int pulseCount;
  final double completion;
  final bool hasFocus;
  final DateTime? lastActivated;

  double get intensity {
    final focusBoost = hasFocus ? 0.18 : 0;
    final pulseBoost = pulseCount * 0.12;
    return (completion + focusBoost + pulseBoost).clamp(0, 1);
  }

  ExperienceOrbit copyWith({
    String? title,
    List<String>? phaseIds,
    List<String>? highlightItemIds,
    int? pulseCount,
    double? completion,
    bool? hasFocus,
    DateTime? lastActivated,
  }) {
    return ExperienceOrbit(
      id: id,
      blueprintId: blueprintId,
      title: title ?? this.title,
      mood: mood,
      phaseIds: phaseIds ?? this.phaseIds,
      highlightItemIds: highlightItemIds ?? this.highlightItemIds,
      pulseCount: pulseCount ?? this.pulseCount,
      completion: completion ?? this.completion,
      hasFocus: hasFocus ?? this.hasFocus,
      lastActivated: lastActivated ?? this.lastActivated,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'blueprintId': blueprintId,
        'title': title,
        'mood': mood.name,
        'phaseIds': phaseIds,
        'highlightItemIds': highlightItemIds,
        'pulseCount': pulseCount,
        'completion': completion,
        'hasFocus': hasFocus,
        'lastActivated': lastActivated?.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceOrbit.fromJson(Map<String, dynamic> json) {
    return ExperienceOrbit(
      id: json['id'] as String,
      blueprintId: json['blueprintId'] as String,
      title: json['title'] as String,
      mood: SceneMood.values.firstWhere(
        (value) => value.name == json['mood'],
        orElse: () => SceneMood.serene,
      ),
      phaseIds: (json['phaseIds'] as List<dynamic>).cast<String>(),
      highlightItemIds:
          (json['highlightItemIds'] as List<dynamic>).cast<String>(),
      pulseCount: json['pulseCount'] as int? ?? 0,
      completion: (json['completion'] as num?)?.toDouble() ?? 0,
      hasFocus: json['hasFocus'] as bool? ?? false,
      lastActivated: json['lastActivated'] == null
          ? null
          : DateTime.parse(json['lastActivated'] as String),
    );
  }

  factory ExperienceOrbit.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceOrbit.fromJson(map);
  }
}
