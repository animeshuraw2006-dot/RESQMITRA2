import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../ui_meta.dart';
import '../widgets.dart';
import 'home.dart';
import 'sos_select.dart';

class _Perm {
  final String key, title, desc;
  final List<Permission> perms; // first = the one that decides the tick
  const _Perm(this.key, this.title, this.desc, this.perms);
}

const _tiles = <_Perm>[
  _Perm('p_location', 'Location', 'Shares your location\nduring an emergency.', [Permission.locationWhenInUse]),
  _Perm('p_notif', 'Notifications', 'Sends instant alerts\nand important updates.', [Permission.notification]),
  _Perm('p_phone', 'Phone / Calling', 'Helps you contact emergency helplines and trusted people.', [Permission.phone, Permission.sms]),
  _Perm('p_contacts', 'Contacts', 'Lets you choose trusted people for emergency alerts.', [Permission.contacts]),
  _Perm('p_mic', 'Microphone', 'Enables voice recording or emergency audio when needed.', [Permission.microphone]),
  _Perm('p_camera', 'Camera', 'Allows you to capture and share photos or videos when requesting help.', [Permission.camera]),
];

/// Every tile asks the real device permission when tapped (live status ticks);
/// "Allow Permissions" walks through all of them one by one.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});
  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<String, bool> _ok = {};
  String? _busy;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    for (final t in _tiles) {
      try {
        if (t.key == 'p_location') {
          final p = await Geolocator.checkPermission();
          _ok[t.key] = p == LocationPermission.whileInUse || p == LocationPermission.always;
        } else {
          _ok[t.key] = await t.perms.first.status.isGranted;
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<bool> _ask(_Perm t) async {
    setState(() => _busy = t.key);
    var ok = false;
    var blocked = false;
    try {
      if (t.key == 'p_location') {
        var p = await Geolocator.requestPermission();
        ok = p == LocationPermission.whileInUse || p == LocationPermission.always;
        blocked = p == LocationPermission.deniedForever;
      } else {
        final st = await t.perms.first.request();
        ok = st.isGranted || st.isLimited;
        blocked = st.isPermanentlyDenied;
        for (final p in t.perms.skip(1)) {
          try {
            await p.request();
          } catch (_) {}
        }
      }
    } catch (_) {}
    if (!mounted) return ok;
    setState(() {
      _ok[t.key] = ok;
      _busy = null;
    });
    if (blocked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${t.title} is blocked. Enable it in Settings.'),
          action: SnackBarAction(label: 'SETTINGS', onPressed: openAppSettings)));
    }
    return ok;
  }

  Future<void> _allowAll() async {
    if (_running) return;
    setState(() => _running = true);
    for (final t in _tiles) {
      if (_ok[t.key] == true) continue;
      await _ask(t);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (mounted) {
      setState(() => _running = false);
      _home();
    }
  }

  void _home() => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);

  Widget _tile(_Perm t, int i) {
    final done = _ok[t.key] == true;
    final busy = _busy == t.key;
    return FadeSlide(
      delayMs: 70 * i,
      child: Pressable(
        onTap: () => _ask(t),
        child: LayoutBuilder(builder: (context, b) {
          final w = b.maxWidth, h = b.maxHeight;
          final bg = Color(UiMeta.bg[t.key]!);
          final arrow = Color(UiMeta.arrow[t.key]!);
          final d = (w * .115).clamp(22.0, 34.0).toDouble();
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(w * .06),
              border: Border.all(color: done ? const Color(0xFF1FB45A) : Colors.white.withValues(alpha: .7), width: done ? 1.6 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Padding(
                  padding: EdgeInsets.only(left: w * .02),
                  child: Image.asset('assets/ui/${t.key}.png', height: h * .84, fit: BoxFit.fitHeight)),
              Expanded(
                  child: Padding(
                padding: EdgeInsets.only(left: w * .015, right: w * .01),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.title,
                      style: TextStyle(fontSize: (w * .078).clamp(11.0, 16.0).toDouble(), fontWeight: FontWeight.w900, color: kNavy)),
                  SizedBox(height: h * .03),
                  Text(t.desc,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: (w * .058).clamp(9.0, 12.5).toDouble(), color: const Color(0xFF33496B), height: 1.25)),
                ]),
              )),
              Padding(
                padding: EdgeInsets.only(right: w * .035),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey('$done$busy'),
                    width: d,
                    height: d,
                    decoration: BoxDecoration(color: done ? const Color(0xFF1FB45A) : arrow, shape: BoxShape.circle),
                    child: busy
                        ? Padding(padding: EdgeInsets.all(d * .25), child: const CircularProgressIndicator(strokeWidth: 2.2, color: kNavy))
                        : Icon(done ? Icons.check : Icons.arrow_forward, size: d * .55, color: done ? Colors.white : kNavy),
                  ),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEFF6FE), Color(0xFFE2F0FC)])),
        child: SafeArea(
          child: Stack(children: [
            Positioned(left: 0, right: 0, bottom: 0, child: CustomPaint(size: Size(W, 90), painter: _WavePainter())),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  height: W * .40,
                  child: Stack(children: [
                    Positioned(left: -6, top: 0, child: IconButton(icon: const Icon(Icons.arrow_back, color: kNavy, size: 30), onPressed: () => Navigator.maybePop(context))),
                    Positioned(left: W * .06, top: W * .05, child: Image.asset('assets/ui/p_logo.png', width: W * .42)),
                    Positioned(right: -W * .05, top: -6, child: Image.asset('assets/ui/p_hero.png', width: W * .50)),
                  ]),
                ),
                const SizedBox(height: 2),
                FadeSlide(child: Text('Allow App Permissions', style: TextStyle(fontSize: (W * .082).clamp(26.0, 36.0).toDouble(), fontWeight: FontWeight.w900, color: const Color(0xFF0B2A6B)))),
                const SizedBox(height: 6),
                Text('To keep you safe and provide quick help,\nRESQ-MITRA needs a few permissions.',
                    style: TextStyle(fontSize: (W * .042).clamp(14.0, 18.0).toDouble(), color: const Color(0xFF3A5673), height: 1.3)),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _tiles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.05),
                    itemBuilder: (_, i) => _tile(_tiles[i], i),
                  ),
                ),
                const SizedBox(height: 10),
                Pressable(
                  onTap: _allowAll,
                  child: Container(
                    height: 58,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C7FE9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: const Color(0xFF0C7FE9).withValues(alpha: .4), blurRadius: 16, offset: const Offset(0, 7))],
                    ),
                    child: _running
                        ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Allow Permissions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward, color: Colors.white),
                          ]),
                  ),
                ),
                Center(
                    child: TextButton(
                        onPressed: _home,
                        child: const Text('Not now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4D6580))))),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 70, child: Divider(color: Color(0xFF2B7FD8), thickness: 1.2)),
                  SizedBox(width: 10),
                  Icon(Icons.monitor_heart, color: Color(0xFF1E7BE0), size: 28),
                  SizedBox(width: 10),
                  SizedBox(width: 70, child: Divider(color: Color(0xFF2B7FD8), thickness: 1.2)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p1 = Path()
      ..moveTo(0, s.height * .55)
      ..quadraticBezierTo(s.width * .25, s.height * .15, s.width * .55, s.height * .5)
      ..quadraticBezierTo(s.width * .8, s.height * .78, s.width, s.height * .35)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(p1, Paint()..color = const Color(0xFFCFE6FB).withValues(alpha: .55));
    final p2 = Path()
      ..moveTo(0, s.height * .8)
      ..quadraticBezierTo(s.width * .3, s.height * .45, s.width * .6, s.height * .8)
      ..quadraticBezierTo(s.width * .85, s.height * 1.0, s.width, s.height * .7)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(p2, Paint()..color = const Color(0xFFBBDCF8).withValues(alpha: .5));
  }

  @override
  bool shouldRepaint(_) => false;
}
