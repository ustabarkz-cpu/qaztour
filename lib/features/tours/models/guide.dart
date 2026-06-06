class GuideModel {
  final String id;
  final String name;
  final String? photoUrl;
  final String? bio;
  final int experienceYears;
  final List<String> languages;
  final double rating;
  final int reviewsCount;
  final String? phone;

  const GuideModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.bio,
    required this.experienceYears,
    required this.languages,
    required this.rating,
    required this.reviewsCount,
    this.phone,
  });

  factory GuideModel.fromMap(Map<String, dynamic> map) => GuideModel(
        id: map['id'] as String,
        name: map['name'] as String,
        photoUrl: map['photo_url'] as String?,
        bio: map['bio'] as String?,
        experienceYears: (map['experience_years'] as num?)?.toInt() ?? 0,
        languages: List<String>.from(map['languages'] ?? []),
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        reviewsCount: (map['reviews_count'] as num?)?.toInt() ?? 0,
        phone: map['phone'] as String?,
      );
}
