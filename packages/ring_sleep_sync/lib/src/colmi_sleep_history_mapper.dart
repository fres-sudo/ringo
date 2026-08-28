import 'package:ring_protocol/ring_protocol.dart';
import 'package:sleep_analysis/sleep_analysis.dart';

/// Converts device-reported COLMI nights into Ringo's source-aware domain.
///
/// COLMI encodes minute offsets relative to its local midnight. The ring does
/// not include a timezone in the history payload, so this mapper anchors those
/// offsets to the phone's local date at sync time, then stores UTC timestamps.
/// This preserves a stable instant while making the assumption explicit.
final class ColmiSleepHistoryMapper {
  const ColmiSleepHistoryMapper();

  static const algorithmVersion = 'colmi-reported-sleep/0.1.0';

  SleepAnalysis map(RingSleepHistory history, {DateTime? syncedAt}) {
    final localNow = (syncedAt ?? DateTime.now()).toLocal();
    final localMidnight = DateTime(localNow.year, localNow.month, localNow.day);
    final sessions =
        history.nights.map((night) => _mapNight(night, localMidnight)).toList()
          ..sort((left, right) => left.startsAt.compareTo(right.startsAt));
    return SleepAnalysis(
      algorithmVersion: algorithmVersion,
      source: SleepStageSource.ringReported,
      sessions: sessions,
      generatedAt: localNow.toUtc(),
    );
  }

  SleepSession _mapNight(RingSleepNight night, DateTime localMidnight) {
    final nightMidnight = localMidnight.subtract(Duration(days: night.daysAgo));
    final startsAt = nightMidnight
        .add(Duration(minutes: night.sleepStartMinute))
        .toUtc();
    var endsAt = nightMidnight
        .add(Duration(minutes: night.sleepEndMinute))
        .toUtc();
    if (!endsAt.isAfter(startsAt)) endsAt = endsAt.add(const Duration(days: 1));

    var cursor = startsAt;
    final stages = <SleepStageSegment>[];
    for (final span in night.stages) {
      if (span.duration <= Duration.zero || !cursor.isBefore(endsAt)) continue;
      final spanEnd = cursor.add(span.duration);
      final segmentEnd = spanEnd.isAfter(endsAt) ? endsAt : spanEnd;
      stages.add(
        SleepStageSegment(
          stage: _mapStage(span.stage),
          startsAt: cursor,
          endsAt: segmentEnd,
          confidence: 1,
        ),
      );
      cursor = segmentEnd;
    }

    return SleepSession(
      id: 'colmi-${startsAt.microsecondsSinceEpoch}',
      startsAt: startsAt,
      endsAt: endsAt,
      source: SleepStageSource.ringReported,
      stages: stages,
      timeZoneOffset: nightMidnight.timeZoneOffset,
    );
  }

  SleepStage _mapStage(RingSleepStage stage) => switch (stage) {
    RingSleepStage.light => SleepStage.light,
    RingSleepStage.deep => SleepStage.deep,
    RingSleepStage.rem => SleepStage.rem,
    RingSleepStage.awake => SleepStage.awake,
  };
}
