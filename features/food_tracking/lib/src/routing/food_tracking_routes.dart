import 'package:go_router/go_router.dart';

import '../presentation/pages/food_tracking_page.dart';
import 'food_tracking_destinations.dart';

/// Route definitions owned by the food-tracking feature.
final foodTrackingRoutes = <RouteBase>[
  GoRoute(
    path: FoodTrackingDestination.foodTracking.path,
    builder: (context, state) => FoodTrackingPage(),
  ),
];
