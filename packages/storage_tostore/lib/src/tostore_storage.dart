import 'package:tostore/tostore.dart';

import 'storage.dart';
import 'storage_key.dart';

/// [Storage] implementation backed by a single ToStore database instance.
final class ToStoreStorage implements Storage {
  ToStoreStorage._(this._database);

  final ToStore _database;

  /// Opens a persistent database at [databasePath].
  ///
  /// On mobile, supply an application-writable directory, typically from
  /// `path_provider`'s `getApplicationDocumentsDirectory`.
  static Future<ToStoreStorage> open({
    required String databasePath,
    String databaseName = 'ringo',
  }) async {
    final database = await ToStore.open(
      dbPath: databasePath,
      dbName: databaseName,
    );
    return ToStoreStorage._(database);
  }

  /// Creates a non-persistent instance, useful for tests and previews.
  static Future<ToStoreStorage> inMemory({String? databaseName}) async {
    final database = await ToStore.memory(dbName: databaseName);
    return ToStoreStorage._(database);
  }

  @override
  Future<void> write<T>(StorageKey<T> key, T value) =>
      _database.kv.set(key.name, key.codec.encode(value));

  @override
  Future<T?> read<T>(StorageKey<T> key) async {
    final value = await _database.kv.get(key.name);
    return value == null ? null : key.codec.decode(value);
  }

  @override
  Future<bool> contains<T>(StorageKey<T> key) => _database.kv.exists(key.name);

  @override
  Future<void> remove<T>(StorageKey<T> key) => _database.kv.remove(key.name);

  @override
  Future<void> clear() => _database.kv.clear();

  @override
  Stream<T?> watch<T>(StorageKey<T> key) => _database.kv
      .watch<Object?>(key.name)
      .map((value) => value == null ? null : key.codec.decode(value));

  /// Releases the underlying database resources.
  Future<void> close({bool keepActiveSpace = true}) =>
      _database.close(keepActiveSpace: keepActiveSpace);
}
