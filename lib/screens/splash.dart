import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../state.dart';
import '../theme.dart';
import 'home.dart';
import 'role_select.dart';

/// Plays the intro video EVERY time the app opens. The first video frame is
/// shown instantly as a still image, so there is never a blank screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _v;
  late final Future<void> _ready;
  Timer? _failsafe;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _ready = AppState.I.init(); // runs in parallel with the video
    _v = VideoPlayerController.asset('assets/intro.mp4', videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    _v.initialize().then((_) async {
      if (!mounted) return;
      // Browsers block autoplay with sound, so the web build plays muted.
      await _v.setVolume(kIsWeb ? 0 : 1);
      await _v.setLooping(false);
      setState(() {});
      try {
        await _v.play();
      } catch (_) {}
      _v.addListener(_watch);
    }).catchError((Object _) {
      _next();
      return null;
    });
    _failsafe = Timer(const Duration(seconds: 11), _next);
  }

  void _watch() {
    final v = _v.value;
    if (v.isInitialized && v.position >= v.duration - const Duration(milliseconds: 80)) _next();
  }

  Future<void> _next() async {
    if (_left || !mounted) return;
    _left = true;
    await _ready;
    if (!mounted) return;
    final dest = AppState.I.registered ? const HomeScreen() : const RoleSelectScreen();
    Navigator.of(context).pushReplacement(fadeRoute(dest));
  }

  @override
  void dispose() {
    _failsafe?.cancel();
    _v.removeListener(_watch);
    _v.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Stack(fit: StackFit.expand, children: [
          // frame 0 of the video – visible immediately, identical to the video start
          Image.asset('assets/intro_first.jpg', fit: BoxFit.cover, gaplessPlayback: true),
          if (_v.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(width: _v.value.size.width, height: _v.value.size.height, child: VideoPlayer(_v)),
            ),
        ]),
      );
}
