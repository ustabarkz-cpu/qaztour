import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

// Set of tour IDs that the current user has favorited
final favoritesProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final data = await supabase
      .from('favorites')
      .select('tour_id')
      .eq('user_id', user.id);
  return (data as List).map((e) => e['tour_id'] as String).toSet();
});

// Favorite tours with full tour data
final favoritesToursProvider = FutureProvider((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final data = await supabase
      .from('favorites')
      .select(
          'tour_id, tours(id, title, description, price_per_person, duration_days, max_people, photo_url, youtube_360_url, locations(name))')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);
  return (data as List)
      .map((e) => e['tours'] as Map<String, dynamic>)
      .toList();
});

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return {};
    final data = await supabase
        .from('favorites')
        .select('tour_id')
        .eq('user_id', user.id);
    return (data as List).map((e) => e['tour_id'] as String).toSet();
  }

  Future<void> toggle(String tourId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final current = state.valueOrNull ?? {};
    if (current.contains(tourId)) {
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('tour_id', tourId);
      state = AsyncData({...current}..remove(tourId));
    } else {
      await supabase
          .from('favorites')
          .insert({'user_id': user.id, 'tour_id': tourId});
      state = AsyncData({...current, tourId});
    }
    ref.invalidate(favoritesToursProvider);
  }
}

final favoritesNotifierProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
