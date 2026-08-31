import 'package:go_router/go_router.dart';

import '../presentation/pages/profile_page.dart';
import 'profile_destinations.dart';

/// Route definitions owned by the profile feature.
final profileRoutes = <RouteBase>[
  GoRoute(
    path: ProfileDestination.profile.path,
    builder: (context, state) => ProfilePage(),
  ),
];
