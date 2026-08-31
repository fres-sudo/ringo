import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:storage_tostore/storage_tostore.dart';

import '../data/datasources/sleep_local_data_source.dart';
import '../data/repositories/sleep_repository_impl.dart';
import '../domain/repositories/sleep_repository.dart';
import '../presentation/controllers/sleep_controller.dart';
import '../presentation/pages/sleep_page.dart';
import 'sleep_destinations.dart';

/// Route definitions and route-scoped dependencies for the sleep feature.
final sleepRoutes = <RouteBase>[
  GoRoute(
    path: SleepDestination.sleep.path,
    builder: (context, state) => MultiProvider(
      providers: [
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
              SleepController(repository: context.read<SleepRepository>())
                ..initialize(),
        ),
      ],
      child: const SleepPage(),
    ),
  ),
];
