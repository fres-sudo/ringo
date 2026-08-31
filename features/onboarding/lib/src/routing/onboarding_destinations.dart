/// Addressable locations owned by the onboarding feature.
enum OnboardingDestination {
  welcome('/'),
  flow('/onboarding');

  const OnboardingDestination(this.path);

  final String path;
}
