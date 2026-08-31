import 'package:go_router/go_router.dart';

import '../presentation/pages/dashboard_page.dart';
import 'dashboard_destinations.dart';

/// Route definitions owned by the dashboard feature.
final dashboardRoutes = <RouteBase>[
  GoRoute(
    path: DashboardDestination.dashboard.path,
    builder: (context, state) => DashboardPage(),
  ),
];
