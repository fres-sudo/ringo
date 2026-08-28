import 'package:equatable/equatable.dart';

/// The source of a stage label. A ring-reported stage should never be presented
/// as if it had been inferred by Ringo, or vice versa.
enum SleepStageSource { ringReported, inferred }

/// A non-clinical sleep stage label for one observation interval.
enum SleepStage { unknown, awake, light, deep, rem }

/// One timestamped, normalized observation interval from a wearable.
///
/// Values are intentionally device-neutral. Protocol-specific decoders are
/// responsible for normalising their raw payloads into this model.
final class SleepEpoch extends Equatable {
  SleepEpoch({
    required this.startsAt,
    required this.duration,
    required this.movement,
    required this.signalQuality,
    this.heartRateBpm,
    this.hrvRmssdMs,
  }) : assert(startsAt.isUtc, 'Use UTC timestamps for normalized epochs.'),
       assert(duration > Duration.zero),
       assert(movement >= 0 && movement <= 1),
       assert(signalQuality >= 0 && signalQuality <= 1),
       assert(heartRateBpm == null || heartRateBpm > 0),
       assert(hrvRmssdMs == null || hrvRmssdMs >= 0);

  final DateTime startsAt;
  final Duration duration;
  final double movement;
  final double signalQuality;
  final double? heartRateBpm;
  final double? hrvRmssdMs;

  DateTime get endsAt => startsAt.add(duration);

  SleepEpoch copyWith({
    DateTime? startsAt,
    Duration? duration,
    double? movement,
    double? signalQuality,
    double? heartRateBpm,
    double? hrvRmssdMs,
  }) => SleepEpoch(
    startsAt: startsAt ?? this.startsAt,
    duration: duration ?? this.duration,
    movement: movement ?? this.movement,
    signalQuality: signalQuality ?? this.signalQuality,
    heartRateBpm: heartRateBpm ?? this.heartRateBpm,
    hrvRmssdMs: hrvRmssdMs ?? this.hrvRmssdMs,
  );

  @override
  List<Object?> get props => [
    startsAt,
    duration,
    movement,
    signalQuality,
    heartRateBpm,
    hrvRmssdMs,
  ];
}

/// A user-specific baseline calculated outside the sleep classifier.
final class SleepBaseline extends Equatable {
  const SleepBaseline({this.restingHeartRateBpm, this.typicalHrvRmssdMs});

  final double? restingHeartRateBpm;
  final double? typicalHrvRmssdMs;

  SleepBaseline copyWith({
    double? restingHeartRateBpm,
    double? typicalHrvRmssdMs,
  }) => SleepBaseline(
    restingHeartRateBpm: restingHeartRateBpm ?? this.restingHeartRateBpm,
    typicalHrvRmssdMs: typicalHrvRmssdMs ?? this.typicalHrvRmssdMs,
  );

  @override
  List<Object?> get props => [restingHeartRateBpm, typicalHrvRmssdMs];
}

/// A classified sleep stage and the confidence attributable to the classifier.
final class SleepStageEstimate extends Equatable {
  const SleepStageEstimate({required this.stage, required this.confidence})
    : assert(confidence >= 0 && confidence <= 1);

  final SleepStage stage;
  final double confidence;

  SleepStageEstimate copyWith({SleepStage? stage, double? confidence}) =>
      SleepStageEstimate(
        stage: stage ?? this.stage,
        confidence: confidence ?? this.confidence,
      );

  @override
  List<Object?> get props => [stage, confidence];
}

/// A contiguous interval presented as one stage in the timeline.
final class SleepStageSegment extends Equatable {
  SleepStageSegment({
    required this.stage,
    required this.startsAt,
    required this.endsAt,
    required this.confidence,
  }) : assert(startsAt.isUtc, 'Use UTC timestamps for stage segments.'),
       assert(endsAt.isUtc, 'Use UTC timestamps for stage segments.'),
       assert(endsAt.isAfter(startsAt)),
       assert(confidence >= 0 && confidence <= 1);

  final SleepStage stage;
  final DateTime startsAt;
  final DateTime endsAt;
  final double confidence;

  Duration get duration => endsAt.difference(startsAt);

  SleepStageSegment copyWith({
    SleepStage? stage,
    DateTime? startsAt,
    DateTime? endsAt,
    double? confidence,
  }) => SleepStageSegment(
    stage: stage ?? this.stage,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    confidence: confidence ?? this.confidence,
  );

  @override
  List<Object?> get props => [stage, startsAt, endsAt, confidence];
}

/// Duration totals derived from the stage timeline of a [SleepSession].
///
/// A duration can be shorter than [SleepSession.duration] when the wearable
/// did not report every interval, so consumers must not assume full coverage.
final class SleepMetrics extends Equatable {
  const SleepMetrics({
    required this.timeInBed,
    required this.asleep,
    required this.awake,
    required this.light,
    required this.deep,
    required this.rem,
    required this.unknown,
  });

  final Duration timeInBed;
  final Duration asleep;
  final Duration awake;
  final Duration light;
  final Duration deep;
  final Duration rem;
  final Duration unknown;

  /// Portion of time in bed labelled as light, deep, or REM sleep.
  double get sleepEfficiency => timeInBed == Duration.zero
      ? 0
      : asleep.inMicroseconds / timeInBed.inMicroseconds;

  /// Portion of the timeline covered by an explicit stage label.
  double get stageCoverage => timeInBed == Duration.zero
      ? 0
      : (asleep + awake + unknown).inMicroseconds / timeInBed.inMicroseconds;

  @override
  List<Object?> get props => [
    timeInBed,
    asleep,
    awake,
    light,
    deep,
    rem,
    unknown,
  ];
}

/// A completed, locally-derived sleep period.
final class SleepSession extends Equatable {
  SleepSession({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.source,
    required List<SleepStageSegment> stages,
    this.timeZoneOffset = Duration.zero,
  }) : stages = List.unmodifiable(
         List<SleepStageSegment>.of(stages)
           ..sort((left, right) => left.startsAt.compareTo(right.startsAt)),
       ),
       assert(id != ''),
       assert(startsAt.isUtc, 'Use UTC timestamps for sleep sessions.'),
       assert(endsAt.isUtc, 'Use UTC timestamps for sleep sessions.'),
       assert(!endsAt.isBefore(startsAt)),
       assert(_hasValidStageTimeline(stages, startsAt, endsAt));

  /// Stable identifier generated by the source adapter for idempotent writes.
  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final SleepStageSource source;
  final List<SleepStageSegment> stages;

  /// Phone offset used when the source was normalized to UTC.
  ///
  /// It preserves the display context without making local time part of the
  /// canonical persisted timestamps.
  final Duration timeZoneOffset;

  Duration get duration => endsAt.difference(startsAt);

  Duration get asleepDuration => stages
      .where(
        (segment) =>
            segment.stage == SleepStage.light ||
            segment.stage == SleepStage.deep ||
            segment.stage == SleepStage.rem,
      )
      .fold(Duration.zero, (total, segment) => total + segment.duration);

  SleepMetrics get metrics {
    Duration durationFor(SleepStage stage) => stages
        .where((segment) => segment.stage == stage)
        .fold(Duration.zero, (total, segment) => total + segment.duration);
    final light = durationFor(SleepStage.light);
    final deep = durationFor(SleepStage.deep);
    final rem = durationFor(SleepStage.rem);
    return SleepMetrics(
      timeInBed: duration,
      asleep: light + deep + rem,
      awake: durationFor(SleepStage.awake),
      light: light,
      deep: deep,
      rem: rem,
      unknown: durationFor(SleepStage.unknown),
    );
  }

  SleepSession copyWith({
    String? id,
    DateTime? startsAt,
    DateTime? endsAt,
    SleepStageSource? source,
    List<SleepStageSegment>? stages,
    Duration? timeZoneOffset,
  }) => SleepSession(
    id: id ?? this.id,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    source: source ?? this.source,
    stages: stages ?? this.stages,
    timeZoneOffset: timeZoneOffset ?? this.timeZoneOffset,
  );

  @override
  List<Object?> get props => [
    id,
    startsAt,
    endsAt,
    source,
    stages,
    timeZoneOffset,
  ];

  static bool _hasValidStageTimeline(
    List<SleepStageSegment> stages,
    DateTime sessionStart,
    DateTime sessionEnd,
  ) {
    final ordered = List<SleepStageSegment>.of(stages)
      ..sort((left, right) => left.startsAt.compareTo(right.startsAt));
    for (var index = 0; index < ordered.length; index++) {
      final segment = ordered[index];
      if (segment.startsAt.isBefore(sessionStart) ||
          segment.endsAt.isAfter(sessionEnd)) {
        return false;
      }
      if (index > 0 && segment.startsAt.isBefore(ordered[index - 1].endsAt)) {
        return false;
      }
    }
    return true;
  }
}

/// The versioned result of an analysis run.
final class SleepAnalysis extends Equatable {
  SleepAnalysis({
    required this.algorithmVersion,
    required this.source,
    required List<SleepSession> sessions,
    required this.generatedAt,
  }) : sessions = List.unmodifiable(
         List<SleepSession>.of(sessions)
           ..sort((left, right) => left.startsAt.compareTo(right.startsAt)),
       ),
       assert(algorithmVersion != ''),
       assert(generatedAt.isUtc, 'Use a UTC analysis timestamp.');

  final String algorithmVersion;
  final SleepStageSource source;
  final List<SleepSession> sessions;
  final DateTime generatedAt;

  SleepAnalysis copyWith({
    String? algorithmVersion,
    SleepStageSource? source,
    List<SleepSession>? sessions,
    DateTime? generatedAt,
  }) => SleepAnalysis(
    algorithmVersion: algorithmVersion ?? this.algorithmVersion,
    source: source ?? this.source,
    sessions: sessions ?? this.sessions,
    generatedAt: generatedAt ?? this.generatedAt,
  );

  @override
  List<Object?> get props => [algorithmVersion, source, sessions, generatedAt];
}
