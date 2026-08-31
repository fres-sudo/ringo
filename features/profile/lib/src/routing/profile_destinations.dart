/// Addressable locations owned by the profile feature.
enum ProfileDestination {
  profile('/profile');

  const ProfileDestination(this.path);

  final String path;
}
