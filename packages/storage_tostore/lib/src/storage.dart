import 'storage_key.dart';

/// Persists values locally by their typed [StorageKey].
///
/// Models and their [StorageKey] definitions belong to the feature that owns
/// them. This interface deliberately has no knowledge of application domains.
abstract interface class Storage {
  /// Stores [value] under [key], replacing any previous value.
  Future<void> write<T>(StorageKey<T> key, T value);

  /// Returns the value stored under [key], or `null` when it does not exist.
  Future<T?> read<T>(StorageKey<T> key);

  /// Whether [key] currently has a stored value.
  Future<bool> contains<T>(StorageKey<T> key);

  /// Removes the value stored under [key].
  Future<void> remove<T>(StorageKey<T> key);

  /// Removes all values in the current storage space.
  Future<void> clear();

  /// Emits the current value and each later change for [key].
  Stream<T?> watch<T>(StorageKey<T> key);
}
