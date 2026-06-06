import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../bookings/models/booking.dart';

final guideBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final guide = await supabase
      .from('guides')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();
  if (guide == null) return [];

  final data = await supabase
      .from('bookings')
      .select('*, tours!inner(title, price_per_person, locations(name), guides(name)), profiles(full_name)')
      .eq('tours.guide_id', guide['id'] as String)
      .order('created_at', ascending: false);
  return (data as List).map((e) => BookingModel.fromMap(e)).toList();
});

class GuideBookingActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateStatus(String bookingId, String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase
          .from('bookings')
          .update({'status': status})
          .eq('id', bookingId);
      ref.invalidate(guideBookingsProvider);
    });
  }
}

final guideBookingActionProvider =
    AsyncNotifierProvider<GuideBookingActionNotifier, void>(
        GuideBookingActionNotifier.new);
