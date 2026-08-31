/// Addressable locations owned by the sleep feature.
enum SleepDestination {
  sleep('/sleep');

  const SleepDestination(this.path);

  final String path;
}
