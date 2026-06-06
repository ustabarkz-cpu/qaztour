import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../tours/providers/tours_provider.dart';
import '../providers/bookings_provider.dart';

class BookingCreateScreen extends ConsumerStatefulWidget {
  final String tourId;

  const BookingCreateScreen({super.key, required this.tourId});

  @override
  ConsumerState<BookingCreateScreen> createState() =>
      _BookingCreateScreenState();
}

class _BookingCreateScreenState extends ConsumerState<BookingCreateScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _peopleCount = 1;

  @override
  Widget build(BuildContext context) {
    final tourAsync = ref.watch(tourDetailProvider(widget.tourId));
    final bookingState = ref.watch(bookingCreateProvider);

    ref.listen(bookingCreateProvider, (prev, next) {
      // Срабатывает только после завершения загрузки (не при первом рендере)
      if (prev?.isLoading == true && next.hasValue && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бронирование отправлено!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.go('/my-bookings');
      }
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Бронирование',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: tourAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tour) {
          if (tour == null) return const SizedBox();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tour.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        if (tour.guideName != null) ...[
                          const SizedBox(height: 4),
                          Text('Гид: ${tour.guideName}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Дата',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Количество человек',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filled(
                      onPressed: _peopleCount > 1
                          ? () => setState(() => _peopleCount--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 16),
                    Text('$_peopleCount',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    IconButton.filled(
                      onPressed: () => setState(() => _peopleCount++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Итого:',
                            style: TextStyle(fontSize: 16)),
                        Text(
                          '${tour.pricePerPerson * _peopleCount} ₸',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: bookingState.isLoading
                      ? null
                      : () => ref
                              .read(bookingCreateProvider.notifier)
                              .create(
                                tourId: widget.tourId,
                                date: _selectedDate,
                                peopleCount: _peopleCount,
                              ),
                  child: bookingState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Подтвердить бронирование'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
