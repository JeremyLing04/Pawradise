class LocationModel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double rating;
  final String category;

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.category,
  });
}
