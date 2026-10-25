import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../nav.dart';
import '../services.dart';
import 'responder_dashboard.dart';
import 'sos_select.dart';

bool _popupOpen = false;

/// Opens the responder's ACTIVE ALERT screen (does nothing if it is already open).
void openActiveAlert() {
  final nav = navKey.currentState;
  if (nav == null || AppNav.I.isOnStack('/responder')) return;
  nav.push(MaterialPageRoute(
      settings: const RouteSettings(name: '/responder'), builder: (_) => const ResponderDashboard()));
}

/// Full-screen SOS pop-up with a looping siren. One tap → Active Alert screen.
Future<void> showAlertPopup(Sos s) async {
  final nav = navKey.currentState;
  if (nav == null || _popupOpen) return; // the newest alert is already in AlertService.active
  _popupOpen = true;
  SirenService.start();
  await nav.push(RawDialogRoute<void>(
    barrierDismissible: false,
    barrierLabel: 'Emergency alert',
    barrierColor: Colors.black.withOpacity(.82),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (c, _, __) => _AlertPopup(sos: s),
    transitionBuilder: (c, a, _, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child)),
  ));
  _popupOpen = false;
  SirenService.stop();
}

class _AlertPopup extends StatefulWidget {
  final Sos sos;
  const _AlertPopup({required this.sos});
  @override
  State<_AlertPopup> createState() => _AlertPopupState();
}

class _AlertPopupState extends State<_AlertPopup> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  Timer? _buzz;
  double? _km;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _buzz = Timer.periodic(const Duration(milliseconds: 1100), (_) => HapticFeedback.heavyImpact());
    _distance();
  }

  Future<void> _distance() async {
    final s = widget.sos;
    if (s.lat == 0) return;
    final p = await LocationService.current();
    if (p == null || !mounted) return;
    setState(() => _km = Geolocator.distanceBetween(p.latitude, p.longitude, s.lat, s.lng) / 1000);
  }

  @override
  void dispose() {
    _buzz?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _respond() {
    SirenService.stop();
    Navigator.of(context).pop();
    openActiveAlert();
  }

  void _dismiss() => Navigator.of(context).pop();

  void _mute() {
    SirenService.stop();
    setState(() => _muted = true);
  }

  Widget _chip(IconData i, String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
            color: c.withOpacity(.14), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(.6))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 15, color: c),
          const SizedBox(width: 6),
          Flexible(child: Text(t, overflow: TextOverflow.ellipsis, style: TextStyle(color: c, fontSize: 12.5, fontWeight: FontWeight.w800))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.sos;
    final art = sosArtwork(s);
    final time = '${s.time.hour.toString().padLeft(2, '0')}:${s.time.minute.toString().padLeft(2, '0')}';
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: _respond, // ONE TAP anywhere on the card
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final glow = .35 + .35 * math.sin(_c.value * 2 * math.pi);
                  return Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A0710), Color(0xFF0B1022)]),
                      border: Border.all(color: const Color(0xFFFF3B4E).withOpacity(.55 + glow * .4), width: 2),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFF1F3D).withOpacity(glow), blurRadius: 46, spreadRadius: 4),
                      ],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      // beacon
                      SizedBox(
                        height: 128,
                        width: 128,
                        child: Stack(alignment: Alignment.center, children: [
                          for (var i = 0; i < 3; i++)
                            Builder(builder: (_) {
                              final t = (_c.value + i / 3) % 1;
                              return Container(
                                width: 56 + 72 * t,
                                height: 56 + 72 * t,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFFF3B4E).withOpacity((1 - t) * .8), width: 2.5)),
                              );
                            }),
                          Container(
                            width: 74,
                            height: 74,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [Color(0xFFFF5A6B), Color(0xFFD1001F)])),
                            child: const Icon(Icons.crisis_alert, color: Colors.white, size: 42),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      const Text('EMERGENCY ALERT',
                          style: TextStyle(color: Color(0xFFFF5A6B), fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
                      const SizedBox(height: 4),
                      const Text('Someone nearby needs help right now',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14.5)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white12)),
                        child: Row(children: [
                          if (art != null)
                            ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(art, width: 62, height: 62, fit: BoxFit.cover))
                          else
                            Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(color: const Color(0xFFFF3B4E).withOpacity(.2), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.warning_rounded, color: Color(0xFFFF5A6B), size: 36)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.type, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(s.name, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                        _chip(Icons.category, s.category, const Color(0xFFFF8FA3)),
                        _chip(Icons.near_me, _km == null ? (s.lat == 0 ? 'Location pending' : 'Locating…') : '${_km!.toStringAsFixed(1)} km away', const Color(0xFF5CC8FF)),
                        _chip(Icons.access_time, time, const Color(0xFFFFC53D)),
                        if (s.highAlert) _chip(Icons.priority_high, 'HIGH ALERT', const Color(0xFFFF3B4E)),
                      ]),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(colors: [Color(0xFFFF4D5E), Color(0xFFD1001F)]),
                          boxShadow: [BoxShadow(color: const Color(0xFFFF1F3D).withOpacity(.55), blurRadius: 18, offset: const Offset(0, 8))],
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('RESPOND NOW', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        TextButton.icon(
                            onPressed: _muted ? null : _mute,
                            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, size: 18, color: Colors.white60),
                            label: Text(_muted ? 'Siren muted' : 'Mute siren', style: const TextStyle(color: Colors.white60))),
                        TextButton(onPressed: _dismiss, child: const Text('Dismiss', style: TextStyle(color: Colors.white60))),
                      ]),
                    ]),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
