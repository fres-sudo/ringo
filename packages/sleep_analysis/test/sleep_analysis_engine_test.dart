import 'package:sleep_analysis/sleep_analysis.dart';
import 'package:test/test.dart';

void main() {
  const estimator = HeuristicSleepStageEstimator();
  final baseline = const SleepBaseline(
    restingHeartRateBpm: 60,
    typicalHrvRmssdMs: 40,
  );

  group('HeuristicSleepStageEstimator', () {
    test('classifies transparent provisional stages', () {
      final estimates = estimator.estimate([
        epoch(movement: 0.6, heartRate: 80, hrv: 20),
        epoch(movement: 0.2, heartRate: 60, hrv: 40),
        epoch(movement: 0.02, heartRate: 50, hrv: 50),
        epoch(movement: 0.1, heartRate: 63, hrv: 35),
      ], baseline: baseline);

      expect(estimates.map((estimate) => estimate.stage), [
        SleepStage.awake,
        SleepStage.light,
        SleepStage.deep,
        SleepStage.rem,
      ]);
    });

    test('marks poor-quality intervals as unknown', () {
      final estimate = estimator.estimate([
        epoch(movement: 0.02, heartRate: 50, hrv: 50, quality: 0.49),
      ], baseline: baseline).single;

      expect(estimate.stage, SleepStage.unknown);
      expect(estimate.confidence, 0);
    });
  });

  group('SleepAnalysisEngine', () {
    test('detects a night and keeps short awakenings inside it', () {
      final start = DateTime.utc(2026, 8, 27, 21);
      final epochs = <SleepEpoch>[
        ...epochsFor(
          start: start,
          count: 20,
          movement: 0.8,
          heartRate: 80,
          hrv: 20,
        ),
        ...epochsFor(
          start: start.add(const Duration(minutes: 10)),
          count: 180,
          movement: 0.2,
          heartRate: 60,
          hrv: 40,
        ),
        ...epochsFor(
          start: start.add(const Duration(minutes: 100)),
          count: 10,
          movement: 0.7,
          heartRate: 75,
          hrv: 20,
        ),
        ...epochsFor(
          start: start.add(const Duration(minutes: 105)),
          count: 180,
          movement: 0.02,
          heartRate: 50,
          hrv: 50,
        ),
        ...epochsFor(
          start: start.add(const Duration(minutes: 195)),
          count: 30,
          movement: 0.8,
          heartRate: 80,
          hrv: 20,
        ),
      ];

      final analysis = SleepAnalysisEngine(
        stageEstimator: estimator,
      ).analyse(epochs, baseline: baseline);

      expect(analysis.sessions, hasLength(1));
      final session = analysis.sessions.single;
      expect(session.startsAt, start.add(const Duration(minutes: 10)));
      expect(session.endsAt, start.add(const Duration(minutes: 195)));
      expect(
        session.stages.map((segment) => segment.stage),
        contains(SleepStage.awake),
      );
      expect(
        session.stages.map((segment) => segment.stage),
        contains(SleepStage.deep),
      );
    });

    test('does not make a session when sleep-like data is too short', () {
      final analysis = SleepAnalysisEngine(stageEstimator: estimator).analyse(
        epochsFor(
          start: DateTime.utc(2026, 8, 27, 21),
          count: 40,
          movement: 0.2,
          heartRate: 60,
          hrv: 40,
        ),
        baseline: baseline,
      );

      expect(analysis.sessions, isEmpty);
    });
  });
}

SleepEpoch epoch({
  double movement = 0.2,
  double heartRate = 60,
  double hrv = 40,
  double quality = 1,
}) => SleepEpoch(
  startsAt: DateTime.utc(2026, 8, 27, 21),
  duration: const Duration(seconds: 30),
  movement: movement,
  signalQuality: quality,
  heartRateBpm: heartRate,
  hrvRmssdMs: hrv,
);

List<SleepEpoch> epochsFor({
  required DateTime start,
  required int count,
  required double movement,
  required double heartRate,
  required double hrv,
}) => List<SleepEpoch>.generate(
  count,
  (index) => SleepEpoch(
    startsAt: start.add(Duration(seconds: index * 30)),
    duration: const Duration(seconds: 30),
    movement: movement,
    signalQuality: 1,
    heartRateBpm: heartRate,
    hrvRmssdMs: hrv,
  ),
  growable: false,
);
