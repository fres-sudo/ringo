import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sleep_analysis/sleep_analysis.dart';
import 'package:ui_kit/ui_kit.dart';

/// A sleep-specific hypnogram that plots each reported stage over a session.
///
/// This intentionally lives in the sleep feature: both the stage scale and
/// the mappings from [SleepStage] to visual treatment are domain-specific.
class SleepStagesChart extends StatelessWidget {
  const SleepStagesChart({super.key, required this.session});

  final SleepSession session;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final durationMinutes = session.duration.inMinutes.toDouble();
    final chartDuration = durationMinutes <= 0 ? 1.0 : durationMinutes;

    return Semantics(
      label: _semanticsLabel(),
      child: ExcludeSemantics(
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: chartDuration,
            minY: 0,
            maxY: 4,
            lineTouchData: const LineTouchData(enabled: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) => FlLine(
                color: colors.border,
                strokeWidth: context.tokens.border.hairline,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  interval: 1,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _stageLabelForLevel(value),
                      style: context.typography.caption.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: chartDuration / 2,
                  getTitlesWidget: (value, meta) {
                    final isStart = value.abs() < 0.1;
                    final isEnd = (value - chartDuration).abs() < 0.1;
                    final isMiddle = (value - chartDuration / 2).abs() < 0.1;
                    if (!isStart && !isMiddle && !isEnd) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        _timeLabel(
                          session.startsAt.add(
                            Duration(minutes: value.round()),
                          ),
                        ),
                        style: context.typography.caption.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              for (final segment in session.stages)
                LineChartBarData(
                  spots: [
                    FlSpot(
                      segment.startsAt
                          .difference(session.startsAt)
                          .inMinutes
                          .toDouble(),
                      _levelFor(segment.stage),
                    ),
                    FlSpot(
                      segment.endsAt
                          .difference(session.startsAt)
                          .inMinutes
                          .toDouble(),
                      _levelFor(segment.stage),
                    ),
                  ],
                  color: _colorFor(context, segment.stage),
                  barWidth: 10,
                  isCurved: false,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
            ],
          ),
          duration: context.tokens.durations.slow,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  String _semanticsLabel() {
    final duration = _formatDuration(session.duration);
    final stages = session.stages
        .map(
          (segment) =>
              '${_label(segment.stage)} for '
              '${_formatDuration(segment.duration)}',
        )
        .join(', ');
    return 'Sleep stages over $duration: $stages';
  }

  Color _colorFor(BuildContext context, SleepStage stage) => switch (stage) {
    SleepStage.awake => context.colors.warning,
    SleepStage.light => context.colors.info,
    SleepStage.deep => context.colors.primary,
    SleepStage.rem => context.colors.success,
    SleepStage.unknown => context.colors.mutedForeground,
  };

  double _levelFor(SleepStage stage) => switch (stage) {
    SleepStage.unknown => 0,
    SleepStage.deep => 1,
    SleepStage.light => 2,
    SleepStage.rem => 3,
    SleepStage.awake => 4,
  };

  String _stageLabelForLevel(double level) => switch (level.round()) {
    0 => 'Unknown',
    1 => 'Deep',
    2 => 'Light',
    3 => 'REM',
    4 => 'Awake',
    _ => '',
  };

  String _timeLabel(DateTime time) {
    final local = time.add(session.timeZoneOffset);
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute${local.hour >= 12 ? ' PM' : ' AM'}';
  }
}

String sleepStageLabel(SleepStage stage) => switch (stage) {
  SleepStage.awake => 'Awake',
  SleepStage.light => 'Light',
  SleepStage.deep => 'Deep',
  SleepStage.rem => 'REM',
  SleepStage.unknown => 'Unknown',
};

String _label(SleepStage stage) => sleepStageLabel(stage);

String _formatDuration(Duration duration) =>
    '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
