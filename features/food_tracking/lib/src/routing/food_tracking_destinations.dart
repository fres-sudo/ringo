/// Addressable locations owned by the food-tracking feature.
enum FoodTrackingDestination {
  foodTracking('/food-tracking');

  const FoodTrackingDestination(this.path);

  final String path;
}
