class BookingModel {
  final String id;
  final String touristId;
  final String tourId;
  final DateTime date;
  final int peopleCount;
  final String status; // pending | accepted | rejected
  final String? tourTitle;
  final int? tourPrice;
  final String? locationName;
  final String? guideName;

  const BookingModel({
    required this.id,
    required this.touristId,
    required this.tourId,
    required this.date,
    required this.peopleCount,
    required this.status,
    this.tourTitle,
    this.tourPrice,
    this.locationName,
    this.guideName,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) => BookingModel(
        id: map['id'] as String,
        touristId: map['tourist_id'] as String,
        tourId: map['tour_id'] as String,
        date: DateTime.parse(map['date'] as String),
        peopleCount: map['people_count'] as int,
        status: map['status'] as String,
        tourTitle: map['tours']?['title'] as String?,
        tourPrice: map['tours']?['price_per_person'] as int?,
        locationName: map['tours']?['locations']?['name'] as String?,
        guideName: map['tours']?['guides']?['name'] as String?,
      );

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
