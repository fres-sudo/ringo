import 'package:storage_tostore/storage_tostore.dart';

/// The required profile data collected during onboarding.
final class OnboardingProfile {
  const OnboardingProfile({
    required this.birthYear,
    required this.sex,
    required this.weight,
    required this.height,
  });

  final String? birthYear;
  final String? sex;
  final String? weight;
  final String? height;

  /// Whether every required onboarding answer was provided.
  bool get isComplete => [
    birthYear,
    sex,
    weight,
    height,
  ].every((value) => value?.trim().isNotEmpty ?? false);
}

/// Persists and restores the profile required to complete onboarding.
///
/// Saving the values separately means an interrupted save is considered
/// incomplete at the next launch, so the user is never sent to the app with a
/// partial profile.
final class OnboardingProfileStorage {
  OnboardingProfileStorage(this._storage);

  final Storage _storage;

  static final _birthYearKey = StorageKey<String>(
    'onboarding.profile.birthYear',
    codec: StorageCodec.identity<String>(),
  );
  static final _sexKey = StorageKey<String>(
    'onboarding.profile.sex',
    codec: StorageCodec.identity<String>(),
  );
  static final _weightKey = StorageKey<String>(
    'onboarding.profile.weight',
    codec: StorageCodec.identity<String>(),
  );
  static final _heightKey = StorageKey<String>(
    'onboarding.profile.height',
    codec: StorageCodec.identity<String>(),
  );

  Future<bool> hasCompletedOnboarding() async => (await read()).isComplete;

  Future<OnboardingProfile> read() async => OnboardingProfile(
    birthYear: await _storage.read(_birthYearKey),
    sex: await _storage.read(_sexKey),
    weight: await _storage.read(_weightKey),
    height: await _storage.read(_heightKey),
  );

  Future<void> save(OnboardingProfile profile) {
    assert(profile.isComplete, 'A complete profile is required.');
    return Future.wait([
      _storage.write(_birthYearKey, profile.birthYear!),
      _storage.write(_sexKey, profile.sex!),
      _storage.write(_weightKey, profile.weight!),
      _storage.write(_heightKey, profile.height!),
    ]);
  }
}
