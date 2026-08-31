import 'package:flutter/widgets.dart';
import 'package:onboarding/onboarding.dart';
import 'package:ringo/app/app.dart';
import 'package:sleep/sleep.dart';
import 'package:storage_tostore/storage_tostore.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationDocumentsDirectory();
  final storage = await ToStoreStorage.open(databasePath: directory.path);
  final hasCompletedOnboarding = await OnboardingProfileStorage(
    storage,
  ).hasCompletedOnboarding();
  final controller = SleepController(
    repository: SleepRepositoryImpl(
      localDataSource: ToStoreSleepLocalDataSource(storage),
    ),
  );
  await controller.initialize();
  runApp(
    RingoApp(
      storage: storage,
      hasCompletedOnboarding: hasCompletedOnboarding,
      sleepController: controller,
      onDispose: storage.close,
    ),
  );
}
