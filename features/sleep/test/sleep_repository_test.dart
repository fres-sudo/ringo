import 'package:flutter_test/flutter_test.dart';
import 'package:sleep/sleep.dart';
import 'package:sleep_analysis/sleep_analysis.dart';
import 'package:storage_tostore/storage_tostore.dart';

void main() {
  test(
    'persists and restores a complete sleep analysis through ToStore',
    () async {
      final storage = await ToStoreStorage.inMemory();
      addTearDown(storage.close);
      final repository = SleepRepositoryImpl(
        localDataSource: ToStoreSleepLocalDataSource(storage),
      );
      final analysis = SleepAnalysis(
        algorithmVersion: 'ring-reported/1',
        source: SleepStageSource.ringReported,
        generatedAt: DateTime.utc(2026, 8, 28, 8),
        sessions: [
          SleepSession(
            id: 'colmi-123',
            startsAt: DateTime.utc(2026, 8, 27, 22, 30),
            endsAt: DateTime.utc(2026, 8, 28, 6, 30),
            source: SleepStageSource.ringReported,
            timeZoneOffset: const Duration(hours: 2),
            stages: [
              SleepStageSegment(
                stage: SleepStage.light,
                startsAt: DateTime.utc(2026, 8, 27, 22, 30),
                endsAt: DateTime.utc(2026, 8, 28, 2, 30),
                confidence: 1,
              ),
              SleepStageSegment(
                stage: SleepStage.deep,
                startsAt: DateTime.utc(2026, 8, 28, 2, 30),
                endsAt: DateTime.utc(2026, 8, 28, 6, 30),
                confidence: 1,
              ),
            ],
          ),
        ],
      );

      await repository.saveAnalysis(analysis);

      final restored = await repository.readLatestAnalysis();
      expect(restored, analysis);
      expect(restored!.sessions.single.metrics.sleepEfficiency, 1);
      expect(restored.sessions.single.timeZoneOffset, const Duration(hours: 2));
    },
  );
}
