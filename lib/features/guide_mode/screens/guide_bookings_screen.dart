import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../bookings/models/booking.dart';
import '../providers/guide_bookings_provider.dart';

class GuideBookingsScreen extends ConsumerWidget {
  const GuideBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(guideBookingsProvider);

    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Заявки на туры',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (bookings) => bookings.isEmpty
            ? const EmptyStateView(
                message: 'Заявок пока нет',
                icon: Icons.inbox_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (_, i) =>
                    _GuideBookingCard(booking: bookings[i]),
              ),
      ),
    );
  }
}

class _GuideBookingCard extends ConsumerWidget {
  final BookingModel booking;

  const _GuideBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(guideBookingActionProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.tourTitle ?? 'Тур',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                    '${booking.date.day}.${booking.date.month}.${booking.date.year}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                const Icon(Icons.people_outline,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${booking.peopleCount} чел.',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            if (booking.isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: actionState.isLoading
                          ? null
                          : () => ref
                              .read(guideBookingActionProvider.notifier)
                              .updateStatus(booking.id, 'rejected'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error),
                      child: const Text('Отклонить'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: actionState.isLoading
                          ? null
                          : () => ref
                              .read(guideBookingActionProvider.notifier)
                              .updateStatus(booking.id, 'accepted'),
                      child: const Text('Принять'),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (booking.isAccepted ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.isAccepted ? 'Принято' : 'Отклонено',
                  style: TextStyle(
                    color: booking.isAccepted
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
