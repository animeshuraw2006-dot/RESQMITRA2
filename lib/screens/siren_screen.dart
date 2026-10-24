import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services.dart';

/// Loud siren + whole-screen blinking BRIGHT RED / BRIGHT BLUE / WHITE.
/// Tap anywhere to stop.
class SirenScreen extends StatefulWidget {
  const SirenScreen({super.key});
  @override
  State<SirenScreen> createState() => _SirenScreenState();
}

class _SirenScreenState extends State<SirenScreen> {
  static const _cols = [Color(0xFFFF0000), Color(0xFF0033FF), Color(0xFFFFFFFF)];
  Timer? _t;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    SirenService.start();
    WakelockPlus.enable();
    _t = Timer.periodic(const Duration(milliseconds: 260), (_) => setState(() => _i++));
  }

  @override
  void dispose() {
    _t?.cancel();
    SirenService.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _cols[_i % 3];
    final fg = bg == Colors.white ? Colors.black : Colors.white;
    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: SizedBox.expand(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.crisis_alert, size: 140, color: fg),
            const SizedBox(height: 16),
            Text('SIREN ON', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: fg)),
            const SizedBox(height: 8),
            Text('Tap anywhere to stop', style: TextStyle(fontSize: 18, color: fg)),
          ]),
        ),
      ),
    );
  }
}
