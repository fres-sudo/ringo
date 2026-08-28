import 'package:app_shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:onboarding/onboarding.dart';
import 'package:ring_transport/ring_transport.dart';
import 'package:ui_kit/ui_kit.dart';

import 'sleep_sync_controller.dart';

class RingoApp extends StatefulWidget {
  const RingoApp({super.key, this.initialRoute});

  /// Allows integration tests and deep links to begin at a primary destination.
  final String? initialRoute;

  @override
  State<RingoApp> createState() => _RingoAppState();
}

class _RingoAppState extends State<RingoApp> {
  late final SleepSyncController _sleepSyncController;

  @override
  void initState() {
    super.initState();
    _sleepSyncController = SleepSyncController();
  }

  @override
  void dispose() {
    _sleepSyncController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ringo',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    initialRoute: widget.initialRoute,
    routes: {
      '/': (_) => _RingoStartPage(onSyncSleep: _sleepSyncController.sync),
      AppRoutes.dashboard: (_) =>
          AppShellPage(sleepAnalysis: _sleepSyncController.analysis),
      AppRoutes.sleep: (_) => AppShellPage(
        initialDestination: AppDestination.sleep,
        sleepAnalysis: _sleepSyncController.analysis,
      ),
      AppRoutes.exercise: (_) => AppShellPage(
        initialDestination: AppDestination.exercise,
        sleepAnalysis: _sleepSyncController.analysis,
      ),
      AppRoutes.foodTracking: (_) => AppShellPage(
        initialDestination: AppDestination.foodTracking,
        sleepAnalysis: _sleepSyncController.analysis,
      ),
      AppRoutes.profile: (_) => AppShellPage(
        initialDestination: AppDestination.profile,
        sleepAnalysis: _sleepSyncController.analysis,
      ),
    },
  );
}

class _RingoStartPage extends StatelessWidget {
  const _RingoStartPage({required this.onSyncSleep});

  final Future<void> Function(RingConnectionLease lease) onSyncSleep;

  @override
  Widget build(BuildContext context) => WelcomePage(
    onContinue: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingFlowPage(
          onSyncSleep: onSyncSleep,
          onComplete: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false),
        ),
      ),
    ),
  );
}
