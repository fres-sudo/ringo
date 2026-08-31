import 'dart:async';

import 'package:app_shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:onboarding/onboarding.dart';
import 'package:ring_transport/ring_transport.dart';
import 'package:provider/provider.dart';
import 'package:sleep/sleep.dart';
import 'package:storage_tostore/storage_tostore.dart';
import 'package:ui_kit/ui_kit.dart';

class RingoApp extends StatefulWidget {
  const RingoApp({
    super.key,
    required this.storage,
    this.hasCompletedOnboarding = false,
    this.initialRoute,
    this.sleepController,
    this.onDispose,
  });

  /// Allows integration tests and deep links to begin at a primary destination.
  final Storage storage;
  final bool hasCompletedOnboarding;
  final String? initialRoute;
  final SleepController? sleepController;
  final Future<void> Function()? onDispose;

  @override
  State<RingoApp> createState() => _RingoAppState();
}

class _RingoAppState extends State<RingoApp> {
  late final SleepController _sleepController;

  @override
  void initState() {
    super.initState();
    _sleepController =
        widget.sleepController ??
        SleepController(
          repository: SleepRepositoryImpl(
            localDataSource: InMemorySleepLocalDataSource(),
          ),
        );
    _sleepController.initialize();
  }

  @override
  void dispose() {
    _sleepController.dispose();
    final onDispose = widget.onDispose;
    if (onDispose != null) unawaited(onDispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _sleepController,
    child: MaterialApp(
      title: 'Ringo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: widget.initialRoute,
      routes: {
        '/': (_) => widget.hasCompletedOnboarding
            ? const AppShellPage()
            : _RingoStartPage(
                profileStorage: OnboardingProfileStorage(widget.storage),
                onSyncSleep: _sleepController.sync,
              ),
        AppRoutes.dashboard: (_) => const AppShellPage(),
        AppRoutes.sleep: (_) =>
            const AppShellPage(initialDestination: AppDestination.sleep),
        AppRoutes.exercise: (_) =>
            const AppShellPage(initialDestination: AppDestination.exercise),
        AppRoutes.foodTracking: (_) =>
            const AppShellPage(initialDestination: AppDestination.foodTracking),
        AppRoutes.profile: (_) =>
            const AppShellPage(initialDestination: AppDestination.profile),
      },
    ),
  );
}

class _RingoStartPage extends StatelessWidget {
  const _RingoStartPage({
    required this.profileStorage,
    required this.onSyncSleep,
  });

  final OnboardingProfileStorage profileStorage;
  final Future<void> Function(RingConnectionLease lease) onSyncSleep;

  @override
  Widget build(BuildContext context) => WelcomePage(
    onContinue: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingFlowPage(
          profileStorage: profileStorage,
          onSyncSleep: onSyncSleep,
          onComplete: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
          },
        ),
      ),
    ),
  );
}
