import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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

// VR-баннер 16:9 с превью картинкой (без YouTube плеера)
class _VrPreviewBlock extends StatelessWidget {
  final String url;
  const _VrPreviewBlock({required this.url});

  String _extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.pathSegments.contains('embed')) return uri.pathSegments.last;
    return uri.queryParameters['v'] ?? uri.pathSegments.last;
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _VrFullscreenScreen(url: url),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _extractVideoId(url);
    final thumbUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Превью картинка с YouTube
            Image.network(
              thumbUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.black87),
            ),
            // Тёмный градиент снизу
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Бейдж 360° сверху слева
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vrpano, color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text('360° VR',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
            // Кнопка Play по центру
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.black, size: 40),
              ),
            ),
            // Подпись снизу
            const Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Text(
                'Нажмите чтобы смотреть VR тур',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Полноэкранный VR
class _VrFullscreenScreen extends StatefulWidget {
  final String url;
  const _VrFullscreenScreen({required this.url});

  @override
  State<_VrFullscreenScreen> createState() => _VrFullscreenScreenState();
}

class _VrFullscreenScreenState extends State<_VrFullscreenScreen> {
  late final WebViewController _controller;

  String _buildHtml(String url) {
    final uri = Uri.tryParse(url);
    String videoId = '';
    if (uri != null) {
      if (uri.pathSegments.contains('embed')) {
        videoId = uri.pathSegments.last;
      } else {
        videoId = uri.queryParameters['v'] ?? uri.pathSegments.last;
      }
    }
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
* { margin:0; padding:0; background:#000; }
body { width:100vw; height:100vh; display:flex; align-items:center; justify-content:center; }
iframe { width:100%; height:100%; border:none; }
</style>
</head>
<body>
<iframe src="https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
  allowfullscreen>
</iframe>
</body>
</html>''';
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..loadHtmlString(_buildHtml(widget.url));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          // Кнопка закрыть
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
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
