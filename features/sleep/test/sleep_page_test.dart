import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep/sleep.dart';
import 'package:sleep_analysis/sleep_analysis.dart';

void main() {
  testWidgets('explains that a ring sync is needed before data is shown', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SleepPage()));

    expect(find.text('No sleep data yet'), findsOneWidget);
    expect(find.textContaining('Connect a supported ring'), findsOneWidget);
  });

  testWidgets('shows the latest device-reported stage breakdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SleepPage(
          analysis: SleepAnalysis(
            algorithmVersion: 'test',
            source: SleepStageSource.ringReported,
            sessions: [
              SleepSession(
                startsAt: DateTime.utc(2026, 8, 27, 23),
                endsAt: DateTime.utc(2026, 8, 28, 7),
                source: SleepStageSource.ringReported,
                stages: [
                  SleepStageSegment(
                    stage: SleepStage.light,
                    startsAt: DateTime.utc(2026, 8, 27, 23),
                    endsAt: DateTime.utc(2026, 8, 28, 4),
                    confidence: 1,
                  ),
                  SleepStageSegment(
                    stage: SleepStage.deep,
                    startsAt: DateTime.utc(2026, 8, 28, 4),
                    endsAt: DateTime.utc(2026, 8, 28, 7),
                    confidence: 1,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Latest sleep'), findsOneWidget);
    expect(find.text('8h 0m'), findsOneWidget);
    expect(find.text('Stages reported by your ring'), findsOneWidget);
    expect(find.text('Stage breakdown'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Deep'), findsOneWidget);
  });
}
