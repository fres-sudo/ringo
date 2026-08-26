/// Converts a domain value to and from a value supported by the storage engine.
///
/// Keep codecs close to their feature models. A feature may, for example,
/// encode a profile to a `Map<String, Object?>` and reconstruct it on reads.
final class StorageCodec<T> {
  const StorageCodec({required this.encode, required this.decode});

  final Object? Function(T value) encode;
  final T Function(Object? value) decode;

  /// A codec for values ToStore can persist without transformation.
  static StorageCodec<T> identity<T>() =>
      StorageCodec<T>(encode: (value) => value, decode: (value) => value as T);
}
