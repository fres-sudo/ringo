import 'package:sleep_analysis/sleep_analysis.dart';

/// Storage representation of a [SleepAnalysis].
///
/// The data model owns its schema and conversion rules; neither the repository
/// nor ToStore needs to know about sleep-domain types.
final class SleepAnalysisData {
  const SleepAnalysisData({
    required this.schemaVersion,
    required this.algorithmVersion,
    required this.source,
    required this.generatedAtUtc,
    required this.sessions,
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final String algorithmVersion;
  final String source;
  final String generatedAtUtc;
  final List<SleepSessionData> sessions;

  factory SleepAnalysisData.fromDomain(SleepAnalysis analysis) =>
      SleepAnalysisData(
        schemaVersion: currentSchemaVersion,
        algorithmVersion: analysis.algorithmVersion,
        source: analysis.source.name,
        generatedAtUtc: analysis.generatedAt.toIso8601String(),
        sessions: analysis.sessions.map(SleepSessionData.fromDomain).toList(),
      );

  factory SleepAnalysisData.fromStorage(Object? value) {
    final map = _map(value);
    final schemaVersion = map['schemaVersion'] as int?;
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException('Unsupported sleep storage schema: $schemaVersion');
    }
    return SleepAnalysisData(
      schemaVersion: schemaVersion!,
      algorithmVersion: map['algorithmVersion']! as String,
      source: map['source']! as String,
      generatedAtUtc: map['generatedAtUtc']! as String,
      sessions: (map['sessions']! as List<Object?>)
          .map(SleepSessionData.fromStorage)
          .toList(growable: false),
    );
  }

  SleepAnalysis toDomain() => SleepAnalysis(
    algorithmVersion: algorithmVersion,
    source: SleepStageSource.values.byName(source),
    generatedAt: DateTime.parse(generatedAtUtc).toUtc(),
    sessions: sessions.map((session) => session.toDomain()).toList(),
  );

  Map<String, Object?> toStorage() => {
    'schemaVersion': schemaVersion,
    'algorithmVersion': algorithmVersion,
    'source': source,
    'generatedAtUtc': generatedAtUtc,
    'sessions': sessions.map((session) => session.toStorage()).toList(),
  };
}

final class SleepSessionData {
  const SleepSessionData({
    required this.id,
    required this.startsAtUtc,
    required this.endsAtUtc,
    required this.source,
    required this.timeZoneOffsetMinutes,
    required this.stages,
  });

  final String id;
  final String startsAtUtc;
  final String endsAtUtc;
  final String source;
  final int timeZoneOffsetMinutes;
  final List<SleepStageSegmentData> stages;

  factory SleepSessionData.fromDomain(SleepSession session) => SleepSessionData(
    id: session.id,
    startsAtUtc: session.startsAt.toIso8601String(),
    endsAtUtc: session.endsAt.toIso8601String(),
    source: session.source.name,
    timeZoneOffsetMinutes: session.timeZoneOffset.inMinutes,
    stages: session.stages.map(SleepStageSegmentData.fromDomain).toList(),
  );

  factory SleepSessionData.fromStorage(Object? value) {
    final map = _map(value);
    return SleepSessionData(
      id: map['id']! as String,
      startsAtUtc: map['startsAtUtc']! as String,
      endsAtUtc: map['endsAtUtc']! as String,
      source: map['source']! as String,
      timeZoneOffsetMinutes: map['timeZoneOffsetMinutes']! as int,
      stages: (map['stages']! as List<Object?>)
          .map(SleepStageSegmentData.fromStorage)
          .toList(growable: false),
    );
  }

  SleepSession toDomain() => SleepSession(
    id: id,
    startsAt: DateTime.parse(startsAtUtc).toUtc(),
    endsAt: DateTime.parse(endsAtUtc).toUtc(),
    source: SleepStageSource.values.byName(source),
    timeZoneOffset: Duration(minutes: timeZoneOffsetMinutes),
    stages: stages.map((stage) => stage.toDomain()).toList(),
  );

  Map<String, Object?> toStorage() => {
    'id': id,
    'startsAtUtc': startsAtUtc,
    'endsAtUtc': endsAtUtc,
    'source': source,
    'timeZoneOffsetMinutes': timeZoneOffsetMinutes,
    'stages': stages.map((stage) => stage.toStorage()).toList(),
  };
}

final class SleepStageSegmentData {
  const SleepStageSegmentData({
    required this.stage,
    required this.startsAtUtc,
    required this.endsAtUtc,
    required this.confidence,
  });

  final String stage;
  final String startsAtUtc;
  final String endsAtUtc;
  final double confidence;

  factory SleepStageSegmentData.fromDomain(SleepStageSegment segment) =>
      SleepStageSegmentData(
        stage: segment.stage.name,
        startsAtUtc: segment.startsAt.toIso8601String(),
        endsAtUtc: segment.endsAt.toIso8601String(),
        confidence: segment.confidence,
      );

  factory SleepStageSegmentData.fromStorage(Object? value) {
    final map = _map(value);
    return SleepStageSegmentData(
      stage: map['stage']! as String,
      startsAtUtc: map['startsAtUtc']! as String,
      endsAtUtc: map['endsAtUtc']! as String,
      confidence: (map['confidence']! as num).toDouble(),
    );
  }

  SleepStageSegment toDomain() => SleepStageSegment(
    stage: SleepStage.values.byName(stage),
    startsAt: DateTime.parse(startsAtUtc).toUtc(),
    endsAt: DateTime.parse(endsAtUtc).toUtc(),
    confidence: confidence,
  );

  Map<String, Object?> toStorage() => {
    'stage': stage,
    'startsAtUtc': startsAtUtc,
    'endsAtUtc': endsAtUtc,
    'confidence': confidence,
  };
}

Map<String, Object?> _map(Object? value) =>
    Map<String, Object?>.from(value! as Map);
