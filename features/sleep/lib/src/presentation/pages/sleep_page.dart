import 'package:flutter/material.dart';
import 'package:sleep_analysis/sleep_analysis.dart';
import 'package:ui_kit/ui_kit.dart';

/// Destination for locally analysed sleep history and insights.
class SleepPage extends StatelessWidget {
  const SleepPage({super.key, this.analysis});

  /// The latest locally stored analysis. A sync repository will supply this
  /// once COLMI sleep history is decoded for a supported firmware.
  final SleepAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    final sessions = analysis?.sessions;
    final latestSession = sessions == null || sessions.isEmpty
        ? null
        : sessions.last;
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
  Widget build(BuildContext context) => Semantics(
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
      ],
    ),
  );
}
