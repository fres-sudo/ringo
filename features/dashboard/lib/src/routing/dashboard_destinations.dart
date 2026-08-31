/// Addressable locations owned by the dashboard feature.
enum DashboardDestination {
  dashboard('/dashboard');

  const DashboardDestination(this.path);

  final String path;
}
