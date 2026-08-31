import 'package:dashboard/dashboard.dart';
import 'package:exercise/exercise.dart';
import 'package:food_tracking/food_tracking.dart';
import 'package:go_router/go_router.dart';
import 'package:profile/profile.dart';
import 'package:sleep/sleep.dart';

import '../presentation/pages/app_shell_page.dart';

/// The persistent primary-navigation shell and its independently navigable
/// feature branches.
final appShellRoutes = <RouteBase>[
  StatefulShellRoute.indexedStack(
    branches: [
      StatefulShellBranch(routes: dashboardRoutes),
      StatefulShellBranch(routes: sleepRoutes),
      StatefulShellBranch(routes: exerciseRoutes),
      StatefulShellBranch(routes: foodTrackingRoutes),
      StatefulShellBranch(routes: profileRoutes),
    ],
    builder: (context, state, navigationShell) =>
        AppShellPage(navigationShell: navigationShell),
  ),
];
