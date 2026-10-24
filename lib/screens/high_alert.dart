import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services.dart';
import '../state.dart';
import 'sos_sent.dart';

/// Blood-red, pulsing HIGH ALERT screen. 5-second countdown → SOS + SMS are sent.
class HighAlertScreen extends StatefulWidget {
  const HighAlertScreen({super.key});
  @override
  State<HighAlertScreen> createState() => _HighAlertScreenState();
}

class _HighAlertScreenState extends State<HighAlertScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  Timer? _t;
  int _left = 5;
  bool _sent = false;
  Sos? _sos;
  double? _lat, _lng;
  String _addr = '';

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    HapticFeedback.heavyImpact();
    LocationService.current().then((p) async {
      if (p == null) return;
      _lat = p.latitude;
      _lng = p.longitude;
      _addr = await LocationService.address(p.latitude, p.longitude);
    });
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left > 1) {
        setState(() => _left--);
        HapticFeedback.heavyImpact();
      } else {
        t.cancel();
        setState(() => _left = 0);
        _fire();
      }
    });
  }

  Future<void> _fire() async {
    if (_lat == null) {
      final p = await LocationService.current();
      _lat = p?.latitude;
      _lng = p?.longitude;
    }
    final s = Sos(
      id: 'sos${DateTime.now().millisecondsSinceEpoch}',
      userId: AppState.I.uid,
      category: 'High Alert',
      type: 'Immediate danger',
      name: AppState.I.name,
      phone: AppState.I.phone,
      lat: _lat ?? 0,
      lng: _lng ?? 0,
      address: _addr,
      highAlert: true,
    );
    AlertService.I.dispatch(s);
    SmsService.toContacts(s.smsText);
    HapticFeedback.vibrate();
    if (mounted) setState(() {
      _sent = true;
      _sos = s;
    });
  }

  void _cancel() {
    _t?.cancel();
    if (_sos != null) {
      AlertService.I.cancel(_sos!);
      SmsService.toContacts('ResQMitra: ${AppState.I.name} is SAFE. The earlier SOS was cancelled.');
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _t?.cancel();
    _pulse.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Widget _stat(IconData i, String t, String s) => Expanded(
        child: Column(children: [
          Icon(i, color: const Color(0xFFFF2D6A), size: 30),
          const SizedBox(height: 6),
          Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          Text(s, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
                gradient: RadialGradient(center: Alignment.topLeft, radius: 1.6, colors: [
              Color.lerp(const Color(0xFF3A0000), const Color(0xFF8B0000), _pulse.value)!,
              Colors.black
            ])),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Transform.scale(
                      scale: 1 + .12 * _pulse.value,
                      child: const Icon(Icons.crisis_alert, color: Colors.red, size: 64)),
                  const Text('HIGH ALERT', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(30)),
                      child: const Text('IMMEDIATE DANGER', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
                  const SizedBox(height: 14),
                  Text(
                      _sent
                          ? 'SOS SENT. Your trusted contacts and rescue services have your location.'
                          : 'Your emergency request is being sent to your trusted contacts and rescue services.',
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 17)),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 250, height: 250,
                        child: CustomPaint(
                          painter: _Ring(_sent ? 1 : (5 - _left + 1) / 5, _pulse.value),
                          child: Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text(_sent ? '✓' : '$_left',
                                  style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.w900)),
                              Text(_sent ? 'SENT' : 'SECONDS',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(.4))),
                    child: Row(children: [
                      _stat(Icons.location_on, 'Location', _sent ? 'Shared' : 'Sharing…'),
                      _stat(Icons.sms, 'SMS', _sent ? 'Sent' : 'Sending…'),
                      _stat(Icons.mic, 'Voice Recording', '(Optional)'),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (_sent && _sos != null)
                    TextButton(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SosSentScreen(sos: _sos!))),
                        child: const Text('Track rescue status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                  SizedBox(
                    width: double.infinity, height: 62,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                      onPressed: _cancel,
                      icon: const CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Icon(Icons.close, color: Colors.red)),
                      label: const Text('CANCEL SOS — I AM SAFE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Your location and details will be shared with the configured responder service.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _Ring extends CustomPainter {
  final double progress, glow;
  _Ring(this.progress, this.glow);
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromCircle(center: s.center(Offset.zero), radius: s.width / 2 - 14);
    c.drawArc(r, 0, math.pi * 2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 14..color = Colors.red.withOpacity(.18));
    c.drawArc(r, -math.pi / 2, math.pi * 2 * progress, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round..color = Colors.red
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4 + 8 * glow));
  }

  @override
  bool shouldRepaint(_Ring o) => o.progress != progress || o.glow != glow;
}
