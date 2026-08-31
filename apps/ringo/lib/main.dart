import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:ringo/app/app.dart';
import 'package:ringo/app/dependency_injector.dart';
import 'package:storage_tostore/storage_tostore.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationDocumentsDirectory();
  final storage = await ToStoreStorage.open(databasePath: directory.path);
  runApp(
    DependencyInjector(
      services: [
        Provider<Storage>(
          create: (_) => storage,
          dispose: (_, storage) => (storage as ToStoreStorage).close(),
        ),
      ],
      child: const RingoApp(),
    ),
  );
}
