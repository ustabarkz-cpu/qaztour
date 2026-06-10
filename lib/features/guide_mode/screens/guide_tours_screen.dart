import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../tours/models/tour.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/guide_tours_provider.dart';

class GuideToursScreen extends ConsumerWidget {
  const GuideToursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toursAsync = ref.watch(guideToursProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Мои туры',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: toursAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (tours) => tours.isEmpty
            ? const EmptyStateView(
                message: 'У вас пока нет туров.\nСвяжитесь с администратором для добавления.',
                icon: Icons.map_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tours.length,
                itemBuilder: (_, i) => _TourCard(tour: tours[i]),
              ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final TourModel tour;
  const _TourCard({required this.tour});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/tour/${tour.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tour.photoUrl != null)
              CachedNetworkImage(
                imageUrl: tour.photoUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(height: 160, color: AppColors.surface),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tour.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  if (tour.locationName != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(tour.locationName!,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${tour.durationDays} дней',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      Text('${tour.pricePerPerson} ₸ / чел.',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
