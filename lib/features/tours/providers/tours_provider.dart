import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/tour.dart';

final allToursProvider = FutureProvider<List<TourModel>>((ref) async {
  final data = await supabase
      .from('tours')
      .select('*, guides(name, photo_url), locations(name)');
  return (data as List).map((e) => TourModel.fromMap(e)).toList();
});

final toursByLocationProvider =
    FutureProvider.family<List<TourModel>, String>((ref, locationId) async {
  final data = await supabase
      .from('tours')
      .select('*, guides(name, photo_url), locations(name)')
      .eq('location_id', locationId);
  return (data as List).map((e) => TourModel.fromMap(e)).toList();
});

final tourDetailProvider =
    FutureProvider.family<TourModel?, String>((ref, id) async {
  final data = await supabase
      .from('tours')
      .select('*, guides(name, photo_url, bio, phone, languages, experience_years), locations(name, lat, lng)')
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return TourModel.fromMap(data);
});
