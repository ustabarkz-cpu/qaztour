import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../tours/models/tour.dart';

final myGuideIdProvider = FutureProvider<String?>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  final guide = await supabase
      .from('guides')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();
  return guide?['id'] as String?;
});

final guideToursProvider = FutureProvider<List<TourModel>>((ref) async {
  final guideId = await ref.watch(myGuideIdProvider.future);
  if (guideId == null) return [];
  final data = await supabase
      .from('tours')
      .select('*, guides(name, photo_url), locations(name, lat, lng)')
      .eq('guide_id', guideId);
  return (data as List).map((e) => TourModel.fromMap(e)).toList();
});
