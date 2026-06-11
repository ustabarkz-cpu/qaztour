import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/guide.dart';
import '../models/review.dart';
import '../models/tour.dart';

// Все гиды для конкретной локации (через tours.guide_ref_id)
final guidesByLocationProvider =
    FutureProvider.family<List<({GuideModel guide, TourModel tour})>, String>(
        (ref, locationId) async {
  final data = await supabase
      .from('tours')
      .select('*, guides!guide_ref_id(*), locations(name, lat, lng)')
      .eq('location_id', locationId)
      .not('guide_ref_id', 'is', null);

  return (data as List).map((e) {
    final guide = GuideModel.fromMap(e['guides'] as Map<String, dynamic>);
    final tour = TourModel.fromMap(e);
    return (guide: guide, tour: tour);
  }).toList()
    ..sort((a, b) => b.guide.rating.compareTo(a.guide.rating));
});

final reviewsByGuideProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, guideId) async {
  final data = await supabase
      .from('reviews')
      .select()
      .eq('guide_id', guideId)
      .order('created_at', ascending: false);

  final reviews = (data as List).cast<Map<String, dynamic>>();
  if (reviews.isEmpty) return [];

  final touristIds = reviews.map((e) => e['tourist_id'] as String).toSet().toList();
  final profiles = await supabase
      .from('profiles')
      .select('id, full_name')
      .inFilter('id', touristIds);
  final names = {
    for (final p in (profiles as List).cast<Map<String, dynamic>>())
      p['id'] as String: p['full_name'] as String?
  };

  return reviews
      .map((e) => ReviewModel.fromMap({...e, 'tourist_name': names[e['tourist_id']]}))
      .toList();
});

final guideDetailProvider =
    FutureProvider.family<GuideModel?, String>((ref, guideId) async {
  final data = await supabase
      .from('guides')
      .select()
      .eq('id', guideId)
      .maybeSingle();
  if (data == null) return null;
  return GuideModel.fromMap(data);
});
