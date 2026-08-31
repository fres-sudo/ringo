import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleep_analysis/sleep_analysis.dart';
import 'package:ui_kit/ui_kit.dart';

import '../controllers/sleep_controller.dart';
import '../widgets/sleep_stages_chart.dart';

/// Destination for browsing locally analysed sleep history and stage insights.
class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SleepController>();
    final selectedDay = _selectedDay ?? _initialSelectedDay(controller);
    final session = controller.sessionForDay(selectedDay);

    return AppScaffold(
      safeArea: true,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.tokens.spacing.sm,
          context.tokens.spacing.sm,
          context.tokens.spacing.sm,
          context.tokens.spacing.xxl,
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.tokens.spacing.sm),
            child: Text('Sleep', style: context.typography.headingLg),
          ),
          SizedBox(height: context.tokens.spacing.sm),
          AppWeekCalendar<SleepSession>(
            selectedDay: selectedDay,
            focusedDay: _selectedDay ?? DateTime.now(),
            onDaySelected: (day, _) {
              setState(() => _selectedDay = DateUtils.dateOnly(day));
            },
            eventLoader: controller.sessionsForDay,
          ),
          SizedBox(height: context.tokens.spacing.lg),
          if (controller.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (session == null)
            _NoSleepForDay(selectedDay: selectedDay)
          else
            _SleepSessionDetails(session: session, selectedDay: selectedDay),
        ],
      ),
    );
  }

  DateTime _initialSelectedDay(SleepController controller) {
    final today = DateUtils.dateOnly(DateTime.now());
    final latest = controller.latestSession;
    if (latest == null) return today;
    final latestDay = _displayDate(latest);
    return _isInCurrentWeek(latestDay, today) ? latestDay : today;
  }

  DateTime _displayDate(SleepSession session) {
    final date = session.endsAt.add(session.timeZoneOffset);
    return DateTime(date.year, date.month, date.day);
  }

  bool _isInCurrentWeek(DateTime date, DateTime today) {
    final firstDayIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final currentWeekStart = _startOfWeek(today, firstDayIndex);
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
    return !date.isBefore(currentWeekStart) && !date.isAfter(currentWeekEnd);
  }
}

class _NoSleepForDay extends StatelessWidget {
  const _NoSleepForDay({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) => AppCard(
    title: 'No sleep data',
    subtitle: MaterialLocalizations.of(context).formatMediumDate(selectedDay),
    child: Text(
      'No sleep session was synced for this day. Connect your ring and sync '
      'its history to see sleep stages here.',
      style: context.typography.bodySm.copyWith(color: context.colors.mutedForeground),
    ),
  );
}

class _SleepSessionDetails extends StatelessWidget {
  const _SleepSessionDetails({required this.session, required this.selectedDay});

  final SleepSession session;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    final durations = _stageDurations(session);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SleepSummaryCard(session: session, selectedDay: selectedDay),
        SizedBox(height: context.tokens.spacing.md),
        AppCard(
          title: 'Sleep stages',
          subtitle: _sessionRange(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 248, child: SleepStagesChart(session: session)),
              SizedBox(height: context.tokens.spacing.md),
              _StageLegend(durations: durations),
            ],
          ),
        ),
        SizedBox(height: context.tokens.spacing.sm),
        Text(
          session.source == SleepStageSource.ringReported
              ? 'Stages reported by your ring'
              : 'Stages are estimates, not clinical measurements',
          textAlign: TextAlign.center,
          style: context.typography.caption.copyWith(color: context.colors.mutedForeground),
        ),
      ],
    );
  }

  Map<SleepStage, Duration> _stageDurations(SleepSession session) => {
    for (final stage in SleepStage.values)
      stage: session.stages
          .where((segment) => segment.stage == stage)
          .fold(Duration.zero, (total, segment) => total + segment.duration),
  };

  String _sessionRange(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    TimeOfDay timeFor(DateTime time) {
      final local = time.add(session.timeZoneOffset);
      return TimeOfDay(hour: local.hour, minute: local.minute);
    }

    return '${localizations.formatTimeOfDay(timeFor(session.startsAt))} – '
        '${localizations.formatTimeOfDay(timeFor(session.endsAt))}';
  }
}

class _SleepSummaryCard extends StatelessWidget {
  const _SleepSummaryCard({required this.session, required this.selectedDay});

  final SleepSession session;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) => AppCard(
    title: MaterialLocalizations.of(context).formatMediumDate(selectedDay),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatDuration(session.duration), style: context.typography.displayMd),
              Text(
                'Time in bed',
                style: context.typography.bodySm.copyWith(color: context.colors.mutedForeground),
              ),
            ],
          ),
        ),
        Text(
          '${_formatDuration(session.asleepDuration)} asleep',
          style: context.typography.titleMd.copyWith(color: context.colors.success),
        ),
      ],
    ),
  );
}

class _StageLegend extends StatelessWidget {
  const _StageLegend({required this.durations});

  final Map<SleepStage, Duration> durations;

  @override
  Widget build(BuildContext context) {
    final reported = durations.entries
        .where((entry) => entry.value > Duration.zero)
        .toList(growable: false);
    return Wrap(
      spacing: context.tokens.spacing.sm,
      runSpacing: context.tokens.spacing.xs,
      children: [
        for (final entry in reported) _StageLegendItem(stage: entry.key, duration: entry.value),
      ],
    );
  }
}

class _StageLegendItem extends StatelessWidget {
  const _StageLegendItem({required this.stage, required this.duration});

  final SleepStage stage;
  final Duration duration;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${sleepStageLabel(stage)}, ${_formatDuration(duration)}',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: _colorFor(context, stage), shape: BoxShape.circle),
          child: const SizedBox(width: 8, height: 8),
        ),
        SizedBox(width: context.tokens.spacing.xxs),
        Text(
          '${sleepStageLabel(stage)} ${_formatDuration(duration)}',
          style: context.typography.caption.copyWith(color: context.colors.mutedForeground),
        ),
      ],
    ),
  );

  Color _colorFor(BuildContext context, SleepStage value) => switch (value) {
    SleepStage.awake => context.colors.warning,
    SleepStage.light => context.colors.info,
    SleepStage.deep => context.colors.primary,
    SleepStage.rem => context.colors.success,
    SleepStage.unknown => context.colors.mutedForeground,
  };
}

DateTime _startOfWeek(DateTime day, int firstDayOfWeekIndex) {
  final normalized = DateUtils.dateOnly(day);
  final offset =
      (normalized.weekday % DateTime.daysPerWeek - firstDayOfWeekIndex + DateTime.daysPerWeek) %
      DateTime.daysPerWeek;
  return normalized.subtract(Duration(days: offset));
}

String _formatDuration(Duration duration) =>
    '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
