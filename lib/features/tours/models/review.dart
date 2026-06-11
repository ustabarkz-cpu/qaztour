class ReviewModel {
  final String id;
  final String touristId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? touristName;

  const ReviewModel({
    required this.id,
    required this.touristId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.touristName,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
        id: map['id'] as String,
        touristId: map['tourist_id'] as String,
        rating: (map['rating'] as num).toInt(),
        comment: map['comment'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        touristName: map['tourist_name'] as String?,
      );
}
