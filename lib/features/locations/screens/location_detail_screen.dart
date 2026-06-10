import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/vr_video_player.dart';
import '../../tours/models/guide.dart';
import '../../tours/models/tour.dart';
import '../../tours/providers/guides_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../providers/locations_provider.dart';

class LocationDetailScreen extends ConsumerWidget {
  final String locationId;

  const LocationDetailScreen({super.key, required this.locationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationDetailProvider(locationId));
    final guidesAsync = ref.watch(guidesByLocationProvider(locationId));

    return Scaffold(
      body: locationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (location) {
          if (location == null) {
            return const Center(child: Text('Место не найдено'));
          }

          return Stack(
            children: [
              // Основной скролл
              CustomScrollView(
                slivers: [
                  // AppBar простой — без фото
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    title: Text(location.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),

                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // VR баннер — на самом верху на всю ширину
                            if (location.youtube360Url != null)
                              VrVideoBanner(
                                videoUrl: location.youtube360Url!,
                                thumbnailUrl: location.photoUrl,
                              )
                            else if (location.photoUrl != null)
                              CachedNetworkImage(
                                imageUrl: location.photoUrl!,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                          ],
                        ),
                        if (location.youtube360Url == null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: guidesAsync.maybeWhen(
                              data: (items) => items.isEmpty
                                  ? const SizedBox()
                                  : _LocationFavoriteButton(
                                      tourId: items.first.tour.id),
                              orElse: () => const SizedBox(),
                            ),
                          ),
                      ],
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // 2. Описание
                          if (location.description != null) ...[
                            Text(
                              location.description!,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 3. Показать на карте
                          if (location.lat != null && location.lng != null) ...[
                            OutlinedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=${location.lat},${location.lng}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                              label: const Text('Показать на карте',
                                  style: TextStyle(color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Список гидов
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text('Доступные гиды',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),

                  guidesAsync.when(
                    loading: () => const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )),
                    error: (e, _) => const SliverToBoxAdapter(child: SizedBox()),
                    data: (items) => SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _GuideCard(
                              guide: items[i].guide, tour: items[i].tour),
                          childCount: items.length,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GuideCard extends ConsumerWidget {
  final GuideModel guide;
  final TourModel tour;
  const _GuideCard({required this.guide, required this.tour});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: guide.photoUrl != null
                      ? NetworkImage(guide.photoUrl!) : null,
                  backgroundColor: AppColors.primaryLight,
                  child: guide.photoUrl == null
                      ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guide.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 15),
                          const SizedBox(width: 3),
                          Text(guide.rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(width: 4),
                          Text('(${guide.reviewsCount})',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text('${guide.experienceYears} лет опыта',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${tour.pricePerPerson} ₸',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 17)),
                    const Text('/ чел.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
            if (guide.languages.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: guide.languages
                    .map((l) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(l,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.push('/book/${tour.id}'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Забронировать',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationFavoriteButton extends ConsumerWidget {
  final String tourId;
  const _LocationFavoriteButton({required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesNotifierProvider).valueOrNull ?? {};
    final isFav = favs.contains(tourId);
    return CircleAvatar(
      backgroundColor: Colors.black.withValues(alpha: 0.4),
      child: IconButton(
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_outline,
          color: isFav ? Colors.red : Colors.white,
        ),
        onPressed: () =>
            ref.read(favoritesNotifierProvider.notifier).toggle(tourId),
      ),
    );
  }
}
