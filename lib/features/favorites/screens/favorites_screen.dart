import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toursAsync = ref.watch(favoritesToursProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Избранное',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: toursAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (tours) => tours.isEmpty
            ? const _EmptyFavorites()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tours.length,
                itemBuilder: (_, i) => _FavoriteTourCard(tour: tours[i]),
              ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_outline, size: 72, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('Пока нет избранных туров',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('Нажмите ♡ на туре чтобы добавить',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
}

class _FavoriteTourCard extends ConsumerWidget {
  final Map<String, dynamic> tour;
  const _FavoriteTourCard({required this.tour});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourId = tour['id'] as String;
    final photoUrl = tour['photo_url'] as String?;
    final locationName = (tour['locations'] as Map?)?['name'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/tour/$tourId'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoUrl != null)
              CachedNetworkImage(
                imageUrl: photoUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(height: 160, color: AppColors.primaryLight),
              )
            else
              Container(height: 160, color: AppColors.primaryLight),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tour['title'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        if (locationName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 2),
                              Text(locationName,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text('${tour['price_per_person']} ₸ / чел.',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () =>
                        ref.read(favoritesNotifierProvider.notifier).toggle(tourId),
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
