import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/tours_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../shared/widgets/vr_video_player.dart';

class TourDetailScreen extends ConsumerWidget {
  final String tourId;

  const TourDetailScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourAsync = ref.watch(tourDetailProvider(tourId));

    return Scaffold(
      body: tourAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (tour) {
          if (tour == null) return const Center(child: Text('Тур не найден'));

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // AppBar без фото — просто название + кнопки
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    actions: [
                      Consumer(builder: (context, ref, _) {
                        final favs =
                            ref.watch(favoritesNotifierProvider).valueOrNull ?? {};
                        final isFav = favs.contains(tourId);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_outline,
                            color: isFav ? Colors.red : Colors.white,
                          ),
                          onPressed: () => ref
                              .read(favoritesNotifierProvider.notifier)
                              .toggle(tourId),
                        );
                      }),
                    ],
                    title: Text(tour.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // VR баннер — главный хедер
                        if (tour.youtube360Url != null)
                          VrVideoBanner(
                            videoUrl: tour.youtube360Url!,
                            thumbnailUrl: tour.photoUrl,
                          )
                        else if (tour.photoUrl != null)
                          CachedNetworkImage(
                            imageUrl: tour.photoUrl!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Локация
                              if (tour.locationName != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 16, color: AppColors.secondary),
                                    const SizedBox(width: 4),
                                    Text(tour.locationName!,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Чипы
                              Row(
                                children: [
                                  _InfoChip(
                                      icon: Icons.schedule,
                                      label: '${tour.durationDays} дней'),
                                  const SizedBox(width: 8),
                                  if (tour.maxPeople != null)
                                    _InfoChip(
                                        icon: Icons.group,
                                        label: 'до ${tour.maxPeople} чел.'),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Описание
                              if (tour.description != null) ...[
                                const Text('Описание',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(tour.description!,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        height: 1.5)),
                                const SizedBox(height: 24),
                              ],

                              // Кнопка карты
                              if (tour.lat != null && tour.lng != null) ...[
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(
                                        'https://www.google.com/maps/search/?api=1&query=${tour.lat},${tour.lng}');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: const Icon(Icons.map_outlined,
                                      color: AppColors.primary),
                                  label: const Text('Показать на карте',
                                      style:
                                          TextStyle(color: AppColors.primary)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    minimumSize:
                                        const Size(double.infinity, 48),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Кнопка "Забронировать"
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Цена',
                            style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                          '${tour.pricePerPerson} ₸ / чел.',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.push('/book/$tourId'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Забронировать',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.secondary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
      );
}
