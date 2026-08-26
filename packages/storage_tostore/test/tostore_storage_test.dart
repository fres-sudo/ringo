import 'package:storage_tostore/storage_tostore.dart';
import 'package:test/test.dart';

void main() {
  const themeKey = StorageKey<String>(
    'settings.theme',
    codec: StorageCodec<String>(encode: _encodeString, decode: _decodeString),
  );

  group('ToStoreStorage', () {
    late ToStoreStorage storage;

    setUp(() async {
      storage = await ToStoreStorage.inMemory();
    });

    tearDown(() => storage.close());

    test('writes, reads, and removes a typed value', () async {
      expect(await storage.read(themeKey), isNull);
      expect(await storage.contains(themeKey), isFalse);

      await storage.write(themeKey, 'dark');

      expect(await storage.read(themeKey), 'dark');
      expect(await storage.contains(themeKey), isTrue);

      await storage.remove(themeKey);

      expect(await storage.read(themeKey), isNull);
    });

    test('clears values in the current storage space', () async {
      await storage.write(themeKey, 'light');

      await storage.clear();

      expect(await storage.read(themeKey), isNull);
    });
  });
}

Object? _encodeString(String value) => value;

String _decodeString(Object? value) => value! as String;
