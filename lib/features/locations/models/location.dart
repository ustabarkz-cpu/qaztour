class LocationModel {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String? youtube360Url;
  final double? lat;
  final double? lng;

  const LocationModel({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    this.youtube360Url,
    this.lat,
    this.lng,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) => LocationModel(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        photoUrl: map['photo_url'] as String?,
        youtube360Url: map['youtube_360_url'] as String?,
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
      );
}
