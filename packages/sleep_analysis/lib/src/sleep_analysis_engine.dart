import 'sleep_models.dart';

/// A replaceable batch classifier. Native implementations must preserve this
/// contract so results remain reproducible across platforms.
abstract interface class SleepStageEstimator {
  List<SleepStageEstimate> estimate(
    List<SleepEpoch> epochs, {
    SleepBaseline baseline = const SleepBaseline(),
  });
}

/// Groups classified epochs into credible sleep sessions.
final class SleepAnalysisEngine {
  SleepAnalysisEngine({required SleepStageEstimator stageEstimator})
    : _stageEstimator = stageEstimator;

  static const algorithmVersion = 'sleep-estimator/0.1.0';
  static const _minimumSessionDuration = Duration(minutes: 90);
  static const _minimumSleepOnset = Duration(minutes: 10);
  static const _minimumWakeTermination = Duration(minutes: 15);
  static const _maximumGap = Duration(minutes: 5);

  final SleepStageEstimator _stageEstimator;

  SleepAnalysis analyse(
    List<SleepEpoch> input, {
    SleepBaseline baseline = const SleepBaseline(),
  }) {
    final epochs = List<SleepEpoch>.of(input)
      ..sort((left, right) => left.startsAt.compareTo(right.startsAt));
    if (epochs.isEmpty) {
      return SleepAnalysis(
        algorithmVersion: algorithmVersion,
        source: SleepStageSource.inferred,
        sessions: const [],
        generatedAt: DateTime.now().toUtc(),
      );
    }

    final estimates = _stageEstimator.estimate(epochs, baseline: baseline);
    if (estimates.length != epochs.length) {
      throw StateError(
        'The stage estimator returned the wrong number of results.',
      );
    }

    final sessions = <SleepSession>[];
    var candidateStart = -1;
    var candidateDuration = Duration.zero;
    var sessionStart = -1;
    var wakeStart = -1;
    var wakeDuration = Duration.zero;

    void resetCandidate() {
      candidateStart = -1;
      candidateDuration = Duration.zero;
    }

    void completeSession(int endExclusive) {
      if (sessionStart < 0 || endExclusive <= sessionStart) return;
      final sessionEpochs = epochs.sublist(sessionStart, endExclusive);
      final sessionEstimates = estimates.sublist(sessionStart, endExclusive);
      final startsAt = sessionEpochs.first.startsAt;
      final endsAt = sessionEpochs.last.endsAt;
      if (endsAt.difference(startsAt) < _minimumSessionDuration) return;
      sessions.add(
        SleepSession(
          id: 'inferred-${startsAt.microsecondsSinceEpoch}',
          startsAt: startsAt,
          endsAt: endsAt,
          source: SleepStageSource.inferred,
          stages: _segments(sessionEpochs, sessionEstimates),
        ),
      );
    }

    for (var index = 0; index < epochs.length; index++) {
      final epoch = epochs[index];
      final estimate = estimates[index];
      final hasGap =
          index > 0 &&
          epoch.startsAt.difference(epochs[index - 1].endsAt) > _maximumGap;
      final sleepLike = _isSleepLike(estimate.stage);

      if (hasGap) {
        completeSession(index);
        resetCandidate();
        sessionStart = -1;
        wakeStart = -1;
        wakeDuration = Duration.zero;
      }

      if (sessionStart < 0) {
        if (sleepLike) {
          candidateStart = candidateStart < 0 ? index : candidateStart;
          candidateDuration += epoch.duration;
          if (candidateDuration >= _minimumSleepOnset) {
            sessionStart = candidateStart;
            wakeStart = -1;
            wakeDuration = Duration.zero;
          }
        } else {
          resetCandidate();
        }
        continue;
      }

      if (sleepLike) {
        wakeStart = -1;
        wakeDuration = Duration.zero;
        continue;
      }

      wakeStart = wakeStart < 0 ? index : wakeStart;
      wakeDuration += epoch.duration;
      if (wakeDuration >= _minimumWakeTermination) {
        completeSession(wakeStart);
        resetCandidate();
        sessionStart = -1;
        wakeStart = -1;
        wakeDuration = Duration.zero;
      }
    }

    completeSession(epochs.length);
    return SleepAnalysis(
      algorithmVersion: algorithmVersion,
      source: SleepStageSource.inferred,
      sessions: sessions,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  static bool _isSleepLike(SleepStage stage) => switch (stage) {
    SleepStage.light || SleepStage.deep || SleepStage.rem => true,
    SleepStage.unknown || SleepStage.awake => false,
  };

  static List<SleepStageSegment> _segments(
    List<SleepEpoch> epochs,
    List<SleepStageEstimate> estimates,
  ) {
    final segments = <SleepStageSegment>[];
    var start = 0;
    for (var index = 1; index <= epochs.length; index++) {
      if (index != epochs.length &&
          estimates[index].stage == estimates[start].stage) {
        continue;
      }
      final interval = estimates.sublist(start, index);
      final averageConfidence =
          interval
              .map((estimate) => estimate.confidence)
              .reduce((sum, confidence) => sum + confidence) /
          interval.length;
      segments.add(
        SleepStageSegment(
          stage: estimates[start].stage,
          startsAt: epochs[start].startsAt,
          endsAt: epochs[index - 1].endsAt,
          confidence: averageConfidence,
        ),
      );
      start = index;
    }
    return segments;
  }
}

/// A transparent, non-clinical estimator used until a validated native model is
/// available for a ring/firmware combination.
final class HeuristicSleepStageEstimator implements SleepStageEstimator {
  const HeuristicSleepStageEstimator();

  @override
  List<SleepStageEstimate> estimate(
    List<SleepEpoch> epochs, {
    SleepBaseline baseline = const SleepBaseline(),
  }) => epochs
      .map((epoch) => _estimateEpoch(epoch, baseline))
      .toList(growable: false);

  SleepStageEstimate _estimateEpoch(SleepEpoch epoch, SleepBaseline baseline) {
    if (epoch.signalQuality < 0.5) {
      return const SleepStageEstimate(stage: SleepStage.unknown, confidence: 0);
    }
    if (epoch.movement >= 0.45) {
      return SleepStageEstimate(
        stage: SleepStage.awake,
        confidence: _confidence(epoch.signalQuality, 0.8),
      );
    }

    final heartRate = epoch.heartRateBpm;
    final hrv = epoch.hrvRmssdMs;
    final deepLike =
        heartRate != null &&
        hrv != null &&
        baseline.restingHeartRateBpm != null &&
        baseline.typicalHrvRmssdMs != null &&
        epoch.movement <= 0.05 &&
        heartRate <= baseline.restingHeartRateBpm! - 5 &&
        hrv >= baseline.typicalHrvRmssdMs! * 1.1;
    if (deepLike) {
      return SleepStageEstimate(
        stage: SleepStage.deep,
        confidence: _confidence(epoch.signalQuality, 0.55),
      );
    }

    final remLike =
        heartRate != null &&
        hrv != null &&
        baseline.restingHeartRateBpm != null &&
        baseline.typicalHrvRmssdMs != null &&
        epoch.movement <= 0.15 &&
        heartRate >= baseline.restingHeartRateBpm! + 2 &&
        hrv <= baseline.typicalHrvRmssdMs! * 0.95;
    if (remLike) {
      return SleepStageEstimate(
        stage: SleepStage.rem,
        confidence: _confidence(epoch.signalQuality, 0.4),
      );
    }

    return SleepStageEstimate(
      stage: SleepStage.light,
      confidence: _confidence(epoch.signalQuality, 0.5),
    );
  }

  double _confidence(double signalQuality, double ceiling) =>
      (signalQuality * ceiling).clamp(0, 1);
}
