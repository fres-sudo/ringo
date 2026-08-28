import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleep_analysis/sleep_analysis.dart';
import 'package:ui_kit/ui_kit.dart';

import '../controllers/sleep_controller.dart';

/// Destination for locally analysed sleep history and insights.
class SleepPage extends StatelessWidget {
  const SleepPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SleepController>();
    final latestSession = controller.latestSession;
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.tokens.spacing.lg),
          child: latestSession == null
              ? const _EmptySleepState()
              : _SleepSessionSummary(session: latestSession),
        ),
      ),
    );
  }
}

class _EmptySleepState extends StatelessWidget {
  const _EmptySleepState();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'No sleep data synced yet',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bedtime_outlined, size: context.tokens.iconSize.lg),
        SizedBox(height: context.tokens.spacing.md),
        Text('No sleep data yet', style: context.typography.titleLg),
        SizedBox(height: context.tokens.spacing.sm),
        const Text(
          'Connect a supported ring and sync its history. Stages appear only '
          'when the device data is available and reliable.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _SleepSessionSummary extends StatelessWidget {
  const _SleepSessionSummary({required this.session});

  final SleepSession session;

  @override
  Widget build(BuildContext context) {
    final stageDurations = <SleepStage, Duration>{
      for (final stage in SleepStage.values)
        stage: session.stages
            .where((segment) => segment.stage == stage)
            .fold(Duration.zero, (total, segment) => total + segment.duration),
    };
    final reportedStages = stageDurations.entries
        .where((entry) => entry.value > Duration.zero)
        .toList();

    return Semantics(
      label: 'Latest sleep session lasted ${session.duration.inHours} hours',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Latest sleep', style: context.typography.titleLg),
          SizedBox(height: context.tokens.spacing.sm),
          Text(
            '${session.duration.inHours}h ${session.duration.inMinutes % 60}m',
          ),
          SizedBox(height: context.tokens.spacing.sm),
          Text(
            session.source == SleepStageSource.ringReported
                ? 'Stages reported by your ring'
                : 'Stages are estimates, not clinical measurements',
            textAlign: TextAlign.center,
          ),
          if (reportedStages.isNotEmpty) ...[
            SizedBox(height: context.tokens.spacing.lg),
            Text('Stage breakdown', style: context.typography.titleMd),
            SizedBox(height: context.tokens.spacing.sm),
            for (final entry in reportedStages)
              _StageDurationRow(stage: entry.key, duration: entry.value),
          ],
        ],
      ),
    );
  }
}

class _StageDurationRow extends StatelessWidget {
  const _StageDurationRow({required this.stage, required this.duration});

  final SleepStage stage;
  final Duration duration;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.tokens.spacing.xxs),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_label(stage)),
        SizedBox(width: context.tokens.spacing.sm),
        Text('${duration.inHours}h ${duration.inMinutes % 60}m'),
      ],
    ),
  );

  String _label(SleepStage value) => switch (value) {
    SleepStage.awake => 'Awake',
    SleepStage.light => 'Light',
    SleepStage.deep => 'Deep',
    SleepStage.rem => 'REM',
    SleepStage.unknown => 'Unknown',
  };
}
