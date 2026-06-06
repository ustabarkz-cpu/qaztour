import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/vr_video_player.dart';
import '../../tours/providers/guides_provider.dart';
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
                    child: Column(
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

class _GuideCard extends StatelessWidget {
  final guide;
  final tour;
  const _GuideCard({required this.guide, required this.tour});

  @override
  Widget build(BuildContext context) {
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
                children: (guide.languages as List<String>)
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

// Старые классы удалены — используется _GuideCard выше

class _OldBookingButton extends StatelessWidget {
  final String locationId;
  final List tours;

  const _OldBookingButton({required this.locationId, required this.tours});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: () {
          if (tours.isNotEmpty) {
            // Если есть туры — показываем выбор
            _showTourPicker(context, tours);
          } else {
            // Если туров нет — прямо к созданию заявки (пустой тур)
            _showNoToursDialog(context);
          }
        },
        icon: const Icon(Icons.send_outlined),
        label: const Text(
          'Создать заявку',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _showTourPicker(BuildContext context, List tours) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Выберите тур',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('или оставьте заявку, и гид сам свяжется с вами',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ...tours.map((tour) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.hiking, color: AppColors.primary),
                  ),
                  title: Text(tour.title,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${tour.pricePerPerson} ₸ · ${tour.durationDays} дн.'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/book/${tour.id}');
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showNoToursDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Туры пока не добавлены'),
        content: const Text(
            'Вы можете оставить заявку и гид свяжется с вами в ближайшее время.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Понятно')),
        ],
      ),
    );
  }
}

// VR баннер 16:9 — тап открывает полный экран
class _VrBanner extends StatelessWidget {
  final String url;
  const _VrBanner({required this.url});

  String _videoId() {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.pathSegments.contains('embed')) return uri.pathSegments.last;
    return uri.queryParameters['v'] ?? uri.pathSegments.last;
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _videoId();
    final thumb = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _VrFullscreen(url: url),
      )),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(thumb, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.black87)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                ),
              ),
            ),
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vrpano, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('360° VR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VrFullscreen extends StatefulWidget {
  final String url;
  const _VrFullscreen({required this.url});

  @override
  State<_VrFullscreen> createState() => _VrFullscreenState();
}

class _VrFullscreenState extends State<_VrFullscreen> {
  late final WebViewController _controller;

  String _buildHtml() {
    final uri = Uri.tryParse(widget.url);
    String videoId = '';
    if (uri != null) {
      if (uri.pathSegments.contains('embed')) {
        videoId = uri.pathSegments.last;
      } else {
        videoId = uri.queryParameters['v'] ?? uri.pathSegments.last;
      }
    }
    return '''<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>*{margin:0;padding:0;background:#000;}body{width:100vw;height:100vh;display:flex;align-items:center;justify-content:center;}iframe{width:100%;height:100%;border:none;}</style>
</head><body><iframe src="https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1"
allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe></body></html>''';
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..loadHtmlString(_buildHtml());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        WebViewWidget(controller: _controller),
        Positioned(
          top: 40, right: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}

class _YoutubeEmbed extends StatefulWidget {
  final String url;

  const _YoutubeEmbed({required this.url});

  @override
  State<_YoutubeEmbed> createState() => _YoutubeEmbedState();
}

class _YoutubeEmbedState extends State<_YoutubeEmbed> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}

class _TourCard extends StatelessWidget {
  final dynamic tour;

  const _TourCard({required this.tour});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/tour/${tour.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Обложка тура
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: tour.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: tour.photoUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              // Информация
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tour.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        if (tour.youtube360Url != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.vrpano,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 3),
                                Text('360°',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${tour.guideName ?? 'Гид'} · ${tour.durationDays} дн.',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          '${tour.pricePerPerson} ₸',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        const Text(' / чел.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 160,
        color: AppColors.surface,
        child: const Center(
          child: Icon(Icons.landscape_outlined, size: 48, color: Colors.grey),
        ),
      );
}
