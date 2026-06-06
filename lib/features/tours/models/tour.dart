class TourModel {
  final String id;
  final String locationId;
  final String guideId;
  final String title;
  final String? description;
  final int pricePerPerson;
  final int durationDays;
  final int? maxPeople;
  final String? guideName;
  final String? guidePhotoUrl;
  final String? locationName;
  final String? photoUrl;
  final String? youtube360Url;
  final double? lat;
  final double? lng;

  const TourModel({
    required this.id,
    required this.locationId,
    required this.guideId,
    required this.title,
    this.description,
    required this.pricePerPerson,
    required this.durationDays,
    this.maxPeople,
    this.guideName,
    this.guidePhotoUrl,
    this.locationName,
    this.photoUrl,
    this.youtube360Url,
    this.lat,
    this.lng,
  });

  factory TourModel.fromMap(Map<String, dynamic> map) => TourModel(
        id: map['id'] as String,
        locationId: map['location_id'] as String,
        guideId: map['guide_id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        pricePerPerson: map['price_per_person'] as int,
        durationDays: map['duration_days'] as int,
        maxPeople: map['max_people'] as int?,
        // guides может прийти и через join guides!guide_ref_id
        guideName: map['guides']?['name'] as String?,
        guidePhotoUrl: map['guides']?['photo_url'] as String?,
        locationName: map['locations']?['name'] as String?,
        photoUrl: map['photo_url'] as String?,
        youtube360Url: map['youtube_360_url'] as String?,
        lat: (map['locations']?['lat'] as num?)?.toDouble(),
        lng: (map['locations']?['lng'] as num?)?.toDouble(),
      );
}
