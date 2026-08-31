import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding/onboarding.dart';
import 'package:storage_tostore/storage_tostore.dart';

void main() {
  late ToStoreStorage storage;
  late OnboardingProfileStorage profileStorage;

  setUp(() async {
    storage = await ToStoreStorage.inMemory();
    profileStorage = OnboardingProfileStorage(storage);
  });
  tearDown(() => storage.close());

  test('is incomplete until every required profile value is stored', () async {
    expect(await profileStorage.hasCompletedOnboarding(), isFalse);

    await profileStorage.save(
      const OnboardingProfile(
        birthYear: '1990',
        sex: 'Female',
        weight: '65 kg',
        height: '170 cm',
      ),
    );

    expect(await profileStorage.hasCompletedOnboarding(), isTrue);
  });
}
