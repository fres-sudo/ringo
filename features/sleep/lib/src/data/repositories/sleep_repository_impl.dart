import 'package:sleep_analysis/sleep_analysis.dart';

import '../../domain/repositories/sleep_repository.dart';
import '../datasources/sleep_local_data_source.dart';
import '../models/sleep_analysis_data.dart';

/// Repository that translates the ToStore schema into immutable domain data.
final class SleepRepositoryImpl implements SleepRepository {
  SleepRepositoryImpl({required SleepLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final SleepLocalDataSource _localDataSource;

  @override
  Future<SleepAnalysis?> readLatestAnalysis() async =>
      (await _localDataSource.readLatestAnalysis())?.toDomain();

  @override
  Future<void> saveAnalysis(SleepAnalysis analysis) => _localDataSource
      .writeLatestAnalysis(SleepAnalysisData.fromDomain(analysis));

  @override
  Stream<SleepAnalysis?> watchLatestAnalysis() => _localDataSource
      .watchLatestAnalysis()
      .map((analysis) => analysis?.toDomain());
}
