import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sleep/sleep.dart';
import 'package:storage_tostore/storage_tostore.dart';

import '../data/onboarding_profile_storage.dart';
import '../presentation/pages/onboarding_flow_page.dart';
import '../presentation/pages/welcome_page.dart';
import 'onboarding_destinations.dart';

/// Route definitions and route-scoped dependencies for the onboarding feature.
///
/// [completedDestination] is composed by the application because the
/// destination belongs to a different feature.
List<RouteBase> onboardingRoutes({required String completedDestination}) => [
  GoRoute(
    path: OnboardingDestination.welcome.path,
    builder: (context, state) => Provider<OnboardingProfileStorage>(
      create: (context) => OnboardingProfileStorage(context.read<Storage>()),
      child: _OnboardingEntryPage(completedDestination: completedDestination),
    ),
  ),
  GoRoute(
    path: OnboardingDestination.flow.path,
    builder: (context, state) => MultiProvider(
      providers: [
        Provider<OnboardingProfileStorage>(
          create: (context) =>
              OnboardingProfileStorage(context.read<Storage>()),
        ),
        Provider<SleepLocalDataSource>(
          create: (context) =>
              ToStoreSleepLocalDataSource(context.read<Storage>()),
        ),
        Provider<SleepRepository>(
          create: (context) => SleepRepositoryImpl(
            localDataSource: context.read<SleepLocalDataSource>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SleepController(repository: context.read<SleepRepository>()),
        ),
      ],
      child: Builder(
        builder: (context) => OnboardingFlowPage(
          profileStorage: context.read<OnboardingProfileStorage>(),
          onSyncSleep: context.read<SleepController>().sync,
          onComplete: () => context.go(completedDestination),
        ),
      ),
    ),
  ),
];

class _OnboardingEntryPage extends StatelessWidget {
  const _OnboardingEntryPage({required this.completedDestination});

  final String completedDestination;

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: context.read<OnboardingProfileStorage>().hasCompletedOnboarding(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Scaffold(body: SizedBox.shrink());
      }
      if (snapshot.requireData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(completedDestination);
        });
        return const Scaffold(body: SizedBox.shrink());
      }
      return WelcomePage(
        onContinue: () => context.go(OnboardingDestination.flow.path),
      );
    },
  );
}
