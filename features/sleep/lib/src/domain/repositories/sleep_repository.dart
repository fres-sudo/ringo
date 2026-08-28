import 'package:sleep_analysis/sleep_analysis.dart';

/// Domain-facing sleep history boundary. Presentation never sees storage.
abstract interface class SleepRepository {
  Future<SleepAnalysis?> readLatestAnalysis();
  Future<void> saveAnalysis(SleepAnalysis analysis);
  Stream<SleepAnalysis?> watchLatestAnalysis();
}
