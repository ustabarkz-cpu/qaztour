import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/booking.dart';

final myBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final data = await supabase
      .from('bookings')
      .select('*, tours(title, price_per_person, locations(name), guides(name))')
      .eq('tourist_id', user.id)
      .not('status', 'in', '("cancelled","rejected")')
      .order('created_at', ascending: false);
  return (data as List).map((e) => BookingModel.fromMap(e)).toList();
});

class BookingCreateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create({
    required String tourId,
    required DateTime date,
    required int peopleCount,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = supabase.auth.currentUser!;
      await supabase.from('bookings').insert({
        'tourist_id': user.id,
        'tour_id': tourId,
        'date': date.toIso8601String().split('T')[0],
        'people_count': peopleCount,
        'status': 'pending',
      });
      ref.invalidate(myBookingsProvider);
    });
  }
}

final bookingCreateProvider =
    AsyncNotifierProvider<BookingCreateNotifier, void>(BookingCreateNotifier.new);

class BookingCancelNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> cancel(String bookingId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
      ref.invalidate(myBookingsProvider);
    });
  }
}

final bookingCancelProvider =
    AsyncNotifierProvider<BookingCancelNotifier, void>(BookingCancelNotifier.new);
