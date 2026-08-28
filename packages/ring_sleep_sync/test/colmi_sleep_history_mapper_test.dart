import 'package:ring_protocol/ring_protocol.dart';
import 'package:ring_sleep_sync/ring_sleep_sync.dart';
import 'package:sleep_analysis/sleep_analysis.dart';
import 'package:test/test.dart';

void main() {
  const mapper = ColmiSleepHistoryMapper();

  test('anchors signed ring offsets and preserves ring-reported stages', () {
    final analysis = mapper.map(
      RingSleepHistory(
        nights: [
          RingSleepNight(
            daysAgo: 1,
            sleepStartMinute: -30,
            sleepEndMinute: 420,
            stages: const [
              RingSleepStageSpan(
                stage: RingSleepStage.light,
                duration: Duration(minutes: 45),
              ),
              RingSleepStageSpan(
                stage: RingSleepStage.deep,
                duration: Duration(minutes: 90),
              ),
            ],
          ),
        ],
      ),
      syncedAt: DateTime.utc(2026, 8, 28, 14),
    );

    final session = analysis.sessions.single;
    expect(analysis.algorithmVersion, ColmiSleepHistoryMapper.algorithmVersion);
    expect(analysis.source, SleepStageSource.ringReported);
    expect(session.startsAt, DateTime(2026, 8, 26, 23, 30).toUtc());
    expect(session.endsAt, DateTime(2026, 8, 27, 7).toUtc());
    expect(session.stages.map((stage) => stage.stage), [
      SleepStage.light,
      SleepStage.deep,
    ]);
    expect(session.stages.last.endsAt, DateTime(2026, 8, 27, 1, 45).toUtc());
  });

  test('sorts nights and caps overstated stage spans at the reported end', () {
    final analysis = mapper.map(
      RingSleepHistory(
        nights: [
          RingSleepNight(
            daysAgo: 0,
            sleepStartMinute: 0,
            sleepEndMinute: 60,
            stages: const [
              RingSleepStageSpan(
                stage: RingSleepStage.rem,
                duration: Duration(minutes: 90),
              ),
            ],
          ),
          RingSleepNight(
            daysAgo: 2,
            sleepStartMinute: 0,
            sleepEndMinute: 60,
            stages: const [],
          ),
        ],
      ),
      syncedAt: DateTime.utc(2026, 8, 28),
    );

    expect(analysis.sessions.first.startsAt, DateTime(2026, 8, 26).toUtc());
    expect(
      analysis.sessions.last.stages.single.duration,
      const Duration(hours: 1),
    );
  });
}
