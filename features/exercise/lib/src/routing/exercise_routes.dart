import 'package:go_router/go_router.dart';

import '../presentation/pages/exercise_page.dart';
import 'exercise_destinations.dart';

/// Route definitions owned by the exercise feature.
final exerciseRoutes = <RouteBase>[
  GoRoute(
    path: ExerciseDestination.exercise.path,
    builder: (context, state) => ExercisePage(),
  ),
];
