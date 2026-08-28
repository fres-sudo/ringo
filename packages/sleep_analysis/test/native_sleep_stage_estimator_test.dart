import 'dart:ffi';
import 'dart:io';

import 'package:sleep_analysis/sleep_analysis.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath = Platform.environment['RINGO_SLEEP_CORE_LIBRARY'];
  test(
    'maps the Rust batch ABI to sleep-stage estimates',
    () {
      final estimator = NativeSleepStageEstimator(
        DynamicLibrary.open(libraryPath!),
      );
      final estimates = estimator.estimate(
        [
          SleepEpoch(
            startsAt: DateTime.utc(2026, 8, 27, 21),
            duration: const Duration(seconds: 30),
            movement: 0.02,
            signalQuality: 1,
            heartRateBpm: 50,
            hrvRmssdMs: 50,
          ),
          SleepEpoch(
            startsAt: DateTime.utc(2026, 8, 27, 21, 0, 30),
            duration: const Duration(seconds: 30),
            movement: 0.7,
            signalQuality: 1,
            heartRateBpm: 80,
            hrvRmssdMs: 20,
          ),
        ],
        baseline: const SleepBaseline(
          restingHeartRateBpm: 60,
          typicalHrvRmssdMs: 40,
        ),
      );

      expect(estimates.map((estimate) => estimate.stage), [
        SleepStage.deep,
        SleepStage.awake,
      ]);
    },
    skip: libraryPath == null
        ? 'Set RINGO_SLEEP_CORE_LIBRARY to run ABI test.'
        : false,
  );
}
