import 'dart:async';

import 'package:storage_tostore/storage_tostore.dart';

import '../models/sleep_analysis_data.dart';

/// Local persistence boundary for the sleep feature.
abstract interface class SleepLocalDataSource {
  Future<SleepAnalysisData?> readLatestAnalysis();
  Future<void> writeLatestAnalysis(SleepAnalysisData analysis);
  Stream<SleepAnalysisData?> watchLatestAnalysis();
}

/// ToStore implementation of [SleepLocalDataSource].
final class ToStoreSleepLocalDataSource implements SleepLocalDataSource {
  ToStoreSleepLocalDataSource(this._storage);

  static const _analysisKey = StorageKey<SleepAnalysisData>(
    'sleep.latest_analysis.v1',
    codec: StorageCodec<SleepAnalysisData>(encode: _encode, decode: _decode),
  );

  final Storage _storage;

  @override
  Future<SleepAnalysisData?> readLatestAnalysis() =>
      _storage.read(_analysisKey);

  @override
  Future<void> writeLatestAnalysis(SleepAnalysisData analysis) =>
      _storage.write(_analysisKey, analysis);

  @override
  Stream<SleepAnalysisData?> watchLatestAnalysis() =>
      _storage.watch(_analysisKey);
}

Object? _encode(SleepAnalysisData value) => value.toStorage();

SleepAnalysisData _decode(Object? value) =>
    SleepAnalysisData.fromStorage(value);

/// Non-persistent source reserved for widget tests and previews.
final class InMemorySleepLocalDataSource implements SleepLocalDataSource {
  final _changes = StreamController<SleepAnalysisData?>.broadcast();
  SleepAnalysisData? _analysis;

  @override
  Future<SleepAnalysisData?> readLatestAnalysis() async => _analysis;

  @override
  Future<void> writeLatestAnalysis(SleepAnalysisData analysis) async {
    _analysis = analysis;
    _changes.add(analysis);
  }

  @override
  Stream<SleepAnalysisData?> watchLatestAnalysis() async* {
    yield _analysis;
    yield* _changes.stream;
  }

  Future<void> dispose() => _changes.close();
}
