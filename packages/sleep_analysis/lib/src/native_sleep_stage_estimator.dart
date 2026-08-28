import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'sleep_analysis_engine.dart';
import 'sleep_models.dart';

/// FFI adapter for the Rust `ringo_sleep_core` batch stage classifier.
///
/// The host application is responsible for bundling `ringo_sleep_core` for its
/// target. This class deliberately accepts a [DynamicLibrary] so it has no
/// platform-specific loading policy and remains testable on every host.
final class NativeSleepStageEstimator implements SleepStageEstimator {
  NativeSleepStageEstimator(DynamicLibrary library)
    : _analyse = library.lookupFunction<_AnalyseNative, _AnalyseDart>(
        'ringo_sleep_analyse_epochs',
      );

  final _AnalyseDart _analyse;

  /// Loads the mobile library packaged by Ringo's Android/iOS build files.
  ///
  /// macOS is intentionally unsupported; local desktop testing should inject a
  /// [DynamicLibrary] directly.
  factory NativeSleepStageEstimator.loadForMobilePlatform() {
    if (Platform.isAndroid) {
      return NativeSleepStageEstimator(
        DynamicLibrary.open('libringo_sleep_core.so'),
      );
    }
    if (Platform.isIOS) {
      return NativeSleepStageEstimator(DynamicLibrary.process());
    }
    throw UnsupportedError(
      'The Ringo sleep core is packaged only for Android and iOS.',
    );
  }

  @override
  List<SleepStageEstimate> estimate(
    List<SleepEpoch> epochs, {
    SleepBaseline baseline = const SleepBaseline(),
  }) {
    if (epochs.isEmpty) return const [];
    final nativeEpochs = calloc<_NativeSleepEpoch>(epochs.length);
    final nativeResults = calloc<_NativeSleepStageEstimate>(epochs.length);
    final config = calloc<_NativeSleepAnalysisConfig>();
    try {
      for (var index = 0; index < epochs.length; index++) {
        final epoch = epochs[index];
        nativeEpochs[index]
          ..timestampSeconds = epoch.startsAt.millisecondsSinceEpoch ~/ 1000
          ..movement = epoch.movement
          ..heartRateBpm = epoch.heartRateBpm ?? double.nan
          ..hrvRmssdMs = epoch.hrvRmssdMs ?? double.nan
          ..signalQuality = epoch.signalQuality;
      }
      config.ref
        ..restingHeartRateBpm = baseline.restingHeartRateBpm ?? double.nan
        ..typicalHrvRmssdMs = baseline.typicalHrvRmssdMs ?? double.nan;
      final count = _analyse(
        nativeEpochs,
        epochs.length,
        config,
        nativeResults,
      );
      if (count != epochs.length) {
        throw StateError(
          'The native sleep estimator rejected the input batch.',
        );
      }
      return List<SleepStageEstimate>.generate(
        count,
        (index) => SleepStageEstimate(
          stage: _toSleepStage(nativeResults[index].stage),
          confidence: nativeResults[index].confidence,
        ),
        growable: false,
      );
    } finally {
      calloc.free(nativeEpochs);
      calloc.free(nativeResults);
      calloc.free(config);
    }
  }

  SleepStage _toSleepStage(int value) => switch (value) {
    1 => SleepStage.awake,
    2 => SleepStage.light,
    3 => SleepStage.deep,
    4 => SleepStage.rem,
    _ => SleepStage.unknown,
  };
}

typedef _AnalyseNative =
    Size Function(
      Pointer<_NativeSleepEpoch> epochs,
      Size count,
      Pointer<_NativeSleepAnalysisConfig> config,
      Pointer<_NativeSleepStageEstimate> results,
    );
typedef _AnalyseDart =
    int Function(
      Pointer<_NativeSleepEpoch> epochs,
      int count,
      Pointer<_NativeSleepAnalysisConfig> config,
      Pointer<_NativeSleepStageEstimate> results,
    );

final class _NativeSleepEpoch extends Struct {
  @Int64()
  external int timestampSeconds;

  @Float()
  external double movement;

  @Float()
  external double heartRateBpm;

  @Float()
  external double hrvRmssdMs;

  @Float()
  external double signalQuality;
}

final class _NativeSleepAnalysisConfig extends Struct {
  @Float()
  external double restingHeartRateBpm;

  @Float()
  external double typicalHrvRmssdMs;
}

final class _NativeSleepStageEstimate extends Struct {
  @Uint8()
  external int stage;

  @Float()
  external double confidence;
}
