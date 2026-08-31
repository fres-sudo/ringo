/// Addressable locations owned by the exercise feature.
enum ExerciseDestination {
  exercise('/exercise');

  const ExerciseDestination(this.path);

  final String path;
}
