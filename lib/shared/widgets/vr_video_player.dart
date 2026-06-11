import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_colors.dart';

class VrVideoBanner extends StatelessWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const VrVideoBanner({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VrVideoFullscreen(videoUrl: videoUrl),
      )),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            thumbnailUrl != null
                ? Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        Container(color: Colors.black87),
                  )
                : Container(color: Colors.black87),

            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vrpano, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('360° VR',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.black, size: 40),
              ),
            ),

            const Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Text(
                'Нажмите чтобы смотреть VR тур',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VrVideoFullscreen extends StatefulWidget {
  final String videoUrl;

  const VrVideoFullscreen({super.key, required this.videoUrl});

  @override
  State<VrVideoFullscreen> createState() => _VrVideoFullscreenState();
}

class _VrVideoFullscreenState extends State<VrVideoFullscreen> {
  late final WebViewController _controller;
  StreamSubscription? _gyroSub;
  Timer? _sendTimer;
  bool _isLoading = true;

  // Видеосфера повёрнута на -90° (rotation="0 -90 0"), поэтому камеру
  // стартуем с тем же смещением по yaw, чтобы не было скачка при первом кадре
  double _yaw = -90.0;
  double _pitch = 0.0;
  DateTime? _lastGyroTime;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initWebView();
    _startGyroscope();
  }

  void _initWebView() {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; }
    body { background: #000; overflow: hidden; width: 100vw; height: 100vh; }
    #hint {
      position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%);
      background: rgba(0,0,0,0.6); color: white; padding: 8px 18px;
      border-radius: 20px; font-family: sans-serif; font-size: 13px;
      pointer-events: none; z-index: 999; transition: opacity 1s;
    }
  </style>
  <script src="https://aframe.io/releases/1.5.0/aframe.min.js"></script>
</head>
<body>
  <div id="hint">📱 Наклоняйте телефон чтобы осмотреться</div>
  <a-scene embedded vr-mode-ui="enabled: false" loading-screen="enabled: false"
    device-orientation-permission-ui="enabled: false">
    <a-assets>
      <video id="v" src="${widget.videoUrl}" crossorigin="anonymous"
        autoplay loop muted playsinline webkit-playsinline></video>
    </a-assets>
    <a-videosphere src="#v" rotation="0 -90 0"></a-videosphere>
    <a-camera id="cam"
      look-controls="enabled: false"
      wasd-controls="enabled: false">
    </a-camera>
  </a-scene>
  <script>
    setTimeout(() => { document.getElementById('hint').style.opacity = '0'; }, 4000);
    document.addEventListener('click', () => {
      const v = document.getElementById('v');
      if (v && v.paused) v.play();
    });
    function setRotation(pitch, yaw) {
      const cam = document.getElementById('cam');
      if (cam) cam.setAttribute('rotation', pitch + ' ' + yaw + ' 0');
    }
  </script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
      ))
      ..loadHtmlString(html);
  }

  void _startGyroscope() {
    // Интегрируем угловую скорость, используя реальное время между событиями
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((GyroscopeEvent e) {
      final now = DateTime.now();
      final last = _lastGyroTime;
      _lastGyroTime = now;
      if (last == null) return;

      final dt = now.difference(last).inMicroseconds / 1e6;
      _yaw   += e.z * dt * (180 / math.pi);
      _pitch += e.x * dt * (180 / math.pi);
      _pitch  = _pitch.clamp(-85.0, 85.0);
    });

    // Шлём накопленный угол в WebView не чаще ~30 раз в секунду,
    // чтобы не перегружать JS-мост частыми вызовами runJavaScript
    _sendTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (_isLoading) return;
      _controller.runJavaScript(
        'setRotation(${_pitch.toStringAsFixed(2)}, ${_yaw.toStringAsFixed(2)});',
      );
    });
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _sendTimer?.cancel();
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
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
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
