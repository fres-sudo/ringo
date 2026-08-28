/// The source of a stage label. A ring-reported stage should never be presented
/// as if it had been inferred by Ringo, or vice versa.
enum SleepStageSource { ringReported, inferred }

/// A non-clinical sleep stage label for one observation interval.
enum SleepStage { unknown, awake, light, deep, rem }

/// One timestamped, normalized observation interval from a wearable.
///
/// Values are intentionally device-neutral. Protocol-specific decoders are
/// responsible for normalising their raw payloads into this model.
final class SleepEpoch {
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
}

/// A user-specific baseline calculated outside the sleep classifier.
final class SleepBaseline {
  const SleepBaseline({this.restingHeartRateBpm, this.typicalHrvRmssdMs});

  final double? restingHeartRateBpm;
  final double? typicalHrvRmssdMs;
}

/// A classified sleep stage and the confidence attributable to the classifier.
final class SleepStageEstimate {
  const SleepStageEstimate({required this.stage, required this.confidence});

  final SleepStage stage;
  final double confidence;
}

/// A contiguous interval presented as one stage in the timeline.
final class SleepStageSegment {
  const SleepStageSegment({
    required this.stage,
    required this.startsAt,
    required this.endsAt,
    required this.confidence,
  });

  final SleepStage stage;
  final DateTime startsAt;
  final DateTime endsAt;
  final double confidence;

  Duration get duration => endsAt.difference(startsAt);
}

/// A completed, locally-derived sleep period.
final class SleepSession {
  SleepSession({
    required this.startsAt,
    required this.endsAt,
    required this.source,
    required List<SleepStageSegment> stages,
  }) : stages = List.unmodifiable(stages),
       assert(!endsAt.isBefore(startsAt));

  final DateTime startsAt;
  final DateTime endsAt;
  final SleepStageSource source;
  final List<SleepStageSegment> stages;

  Duration get duration => endsAt.difference(startsAt);

  Duration get asleepDuration => stages
      .where((segment) => segment.stage != SleepStage.awake)
      .fold(Duration.zero, (total, segment) => total + segment.duration);
}

/// The versioned result of an analysis run.
final class SleepAnalysis {
  SleepAnalysis({
    required this.algorithmVersion,
    required this.source,
    required List<SleepSession> sessions,
  }) : sessions = List.unmodifiable(sessions);

  final String algorithmVersion;
  final SleepStageSource source;
  final List<SleepSession> sessions;
}
