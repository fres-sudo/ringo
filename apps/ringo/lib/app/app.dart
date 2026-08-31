import 'package:app_shell/app_shell.dart';
import 'package:dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onboarding/onboarding.dart';
import 'package:ui_kit/ui_kit.dart';

class RingoApp extends StatefulWidget {
  const RingoApp({super.key, this.initialRoute});

  /// Allows integration tests and deep links to begin at a primary destination.
  final String? initialRoute;

  @override
  State<RingoApp> createState() => _RingoAppState();
}

class _RingoAppState extends State<RingoApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialRoute ?? OnboardingDestination.welcome.path,
    routes: [
      ...onboardingRoutes(
        completedDestination: DashboardDestination.dashboard.path,
      ),
      ...appShellRoutes,
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Ringo',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    routerConfig: _router,
  );
}
