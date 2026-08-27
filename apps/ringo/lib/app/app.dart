import 'package:app_shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:onboarding/onboarding.dart';
import 'package:ui_kit/ui_kit.dart';

class RingoApp extends StatelessWidget {
  const RingoApp({super.key, this.initialRoute});

  /// Allows integration tests and deep links to begin at a primary destination.
  final String? initialRoute;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ringo',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    initialRoute: initialRoute,
    routes: {
      '/': (_) => const _RingoStartPage(),
      AppRoutes.dashboard: (_) => const AppShellPage(),
      AppRoutes.sleep:
          (_) => const AppShellPage(initialDestination: AppDestination.sleep),
      AppRoutes.exercise:
          (_) =>
              const AppShellPage(initialDestination: AppDestination.exercise),
      AppRoutes.foodTracking:
          (_) => const AppShellPage(
            initialDestination: AppDestination.foodTracking,
          ),
      AppRoutes.profile:
          (_) => const AppShellPage(initialDestination: AppDestination.profile),
    },
  );
}

class _RingoStartPage extends StatelessWidget {
  const _RingoStartPage();

  @override
  Widget build(BuildContext context) => WelcomePage(
    onContinue:
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder:
                (_) => OnboardingFlowPage(
                  onComplete:
                      () => Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.dashboard,
                        (route) => false,
                      ),
                ),
          ),
        ),
  );
}
