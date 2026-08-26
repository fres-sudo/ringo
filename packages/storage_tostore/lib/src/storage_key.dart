import 'storage_codec.dart';

/// A namespaced, typed storage key and its serialization contract.
final class StorageKey<T> {
  const StorageKey(this.name, {required this.codec}) : assert(name != '');

  /// Use a feature namespace, such as `profile.current`.
  final String name;
  final StorageCodec<T> codec;
}
