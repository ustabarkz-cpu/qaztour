import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../locations/models/location.dart';
import '../../locations/providers/locations_provider.dart';
import '../../../shared/widgets/vr_video_player.dart';

class AiSuggestion {
  final String locationId;
  final String message;

  const AiSuggestion({required this.locationId, required this.message});
}

class AiAssistantCard extends ConsumerStatefulWidget {
  const AiAssistantCard({super.key});

  @override
  ConsumerState<AiAssistantCard> createState() => _AiAssistantCardState();
}

class _AiAssistantCardState extends ConsumerState<AiAssistantCard> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  AiSuggestion? _suggestion;
  LocationModel? _location;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _suggestion = null;
      _location = null;
    });

    final locations = ref.read(locationsProvider).valueOrNull ?? [];

    try {
      await Future.delayed(const Duration(milliseconds: 900));
      final suggestion = _localSuggestion(text, locations);

      LocationModel? location;
      try {
        location = locations.firstWhere((l) => l.id == suggestion?.locationId);
      } catch (_) {
        location = null;
      }

      setState(() {
        _suggestion = suggestion;
        _location = location;
      });
    } catch (e) {
      setState(() => _error = 'Не удалось получить ответ: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  AiSuggestion? _localSuggestion(String request, List<LocationModel> locations) {
    if (locations.isEmpty) return null;

    final words = request
        .toLowerCase()
        .split(RegExp(r'[^a-zа-яё0-9]+'))
        .where((w) => w.length > 2)
        .toSet();

    final vrLocations = locations.where((l) => l.youtube360Url != null).toList();
    final candidates = vrLocations.isNotEmpty ? vrLocations : locations;

    LocationModel best = candidates.first;
    int bestScore = -1;
    for (final loc in candidates) {
      final text = '${loc.name} ${loc.description ?? ''}'.toLowerCase();
      final score = words.where((w) => text.contains(w)).length;
      if (score > bestScore) {
        bestScore = score;
        best = loc;
      }
    }

    final message = bestScore > 0
        ? '«${best.name}» подходит под ваш запрос лучше всего. '
            'Посмотрите VR 360°-превью и выберите гида для поездки — '
            'возьмите с собой воду и удобную обувь.'
        : 'Пока не нашли точное совпадение, но вот интересное место — «${best.name}». '
            'Загляните в VR 360°-превью и список гидов, чтобы спланировать поездку.';

    return AiSuggestion(locationId: best.id, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('AI Travel Assistant',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Куда хотите поехать?',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Например: красивые каньоны, бюджет 30 000',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _ask(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _loading ? null : _ask,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.white)),
          ],
          if (_suggestion != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_location != null)
                    Text(_location!.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(_suggestion!.message,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.4)),
                  if (_location?.youtube360Url != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: VrVideoBanner(
                        videoUrl: _location!.youtube360Url!,
                        thumbnailUrl: _location!.photoUrl,
                      ),
                    ),
                  ],
                  if (_location != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/location/${_location!.id}'),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Смотреть локацию и гидов'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
