import 'dart:convert';

import 'showroom_scene.dart';

enum ExperienceMomentKind {
  pulse,
  progress,
  focus,
  reflection,
  orbit,
  constellation,
  horizon,
}

class ExperienceMoment {
  ExperienceMoment({
    required this.id,
    required this.blueprintId,
    this.phaseId,
    required this.kind,
    required this.title,
    required this.detail,
    required this.timestamp,
    required this.mood,
  });

  final String id;
  final String blueprintId;
  final String? phaseId;
  final ExperienceMomentKind kind;
  final String title;
  final String detail;
  final DateTime timestamp;
  final SceneMood mood;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'blueprintId': blueprintId,
        'phaseId': phaseId,
        'kind': kind.name,
        'title': title,
        'detail': detail,
        'timestamp': timestamp.toIso8601String(),
        'mood': mood.name,
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceMoment.fromJson(Map<String, dynamic> json) {
    return ExperienceMoment(
      id: json['id'] as String,
      blueprintId: json['blueprintId'] as String,
      phaseId: json['phaseId'] as String?,
      kind: ExperienceMomentKind.values
          .firstWhere((value) => value.name == json['kind']),
      title: json['title'] as String,
      detail: json['detail'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mood: SceneMood.values.firstWhere(
        (value) => value.name == json['mood'],
        orElse: () => SceneMood.serene,
      ),
    );
  }

  factory ExperienceMoment.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceMoment.fromJson(map);
  }
}

class ExperienceFocus {
  ExperienceFocus({
    required this.blueprintId,
    required this.phaseId,
    required this.startedAt,
  });

  final String blueprintId;
  final String phaseId;
  final DateTime startedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'blueprintId': blueprintId,
        'phaseId': phaseId,
        'startedAt': startedAt.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  factory ExperienceFocus.fromJson(Map<String, dynamic> json) {
    return ExperienceFocus(
      blueprintId: json['blueprintId'] as String,
      phaseId: json['phaseId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
    );
  }

  factory ExperienceFocus.fromEncoded(String encoded) {
    final Map<String, dynamic> map =
        jsonDecode(encoded) as Map<String, dynamic>;
    return ExperienceFocus.fromJson(map);
  }
}
