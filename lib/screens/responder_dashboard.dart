import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../api.dart';
import '../badges.dart';
import '../services.dart';
import '../state.dart';
import '../widgets.dart';
import 'sos_select.dart';

// ── palette: deep navy + emergency red ──
const _bg = Color(0xFF060C1F);
const _card = Color(0xFF0D1733);
const _line = Color(0xFF1C2B55);
const _red = Color(0xFFFF3B4E);
const _ice = Color(0xFF8DB8FF);
const _green = Color(0xFF22C55E);

class ResponderDashboard extends StatefulWidget {
  const ResponderDashboard({super.key});
  @override
  State<ResponderDashboard> createState() => _ResponderDashboardState();
}

class _ResponderDashboardState extends State<ResponderDashboard> with SingleTickerProviderStateMixin {
  int _tab = 0;
  Position? _me;
  StreamSubscription<Position>? _pos;
  Timer? _tick;
  String? _seenId;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _seenId = AlertService.I.active?.id;
    AlertService.I.addListener(_onAlert);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => mounted && AlertService.I.active != null ? setState(() {}) : null);
    _startTracking();
  }

  // a NEW alert always brings the responder back to the Active Alert tab
  void _onAlert() {
    final id = AlertService.I.active?.id;
    if (id != null && id != _seenId && mounted) {
      _seenId = id;
      setState(() => _tab = 0);
    }
  }

  Future<void> _startTracking() async {
    final first = await LocationService.current();
    if (mounted) setState(() => _me = first);
    try {
      _pos = Geolocator.getPositionStream(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10))
          .listen((p) => mounted ? setState(() => _me = p) : null);
    } catch (_) {}
  }

  @override
  void dispose() {
    AlertService.I.removeListener(_onAlert);
    _pos?.cancel();
    _tick?.cancel();
    _pulse.dispose();
    SirenService.stop();
    super.dispose();
  }

  double? _km(Sos s) =>
      _me == null || s.lat == 0 ? null : Geolocator.distanceBetween(_me!.latitude, _me!.longitude, s.lat, s.lng) / 1000;

  String _ago(Sos s) {
    final d = DateTime.now().difference(s.time);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    return '${d.inHours} h ago';
  }

  // ───────────── small building blocks ─────────────
  Widget _panel({required Widget child, EdgeInsets pad = const EdgeInsets.all(16), List<Color>? grad, Color? border}) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: pad,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: grad == null ? null : LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
          color: grad == null ? _card : null,
          border: Border.all(color: border ?? _line),
        ),
        child: child,
      );

  Widget _h(String t, {IconData? i, Color c = _ice}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          if (i != null) ...[Icon(i, size: 18, color: c), const SizedBox(width: 8)],
          Text(t.toUpperCase(), style: TextStyle(color: c, fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
        ]),
      );

  Widget _pill(String t, Color c, {IconData? i}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: c.withOpacity(.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(.55))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (i != null) ...[Icon(i, size: 13, color: c), const SizedBox(width: 5)],
          Text(t, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 108, child: Text(k, style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
        ]),
      );

  Widget _gradBtn(String label, IconData i, List<Color> g, VoidCallback? onTap) => Opacity(
        opacity: onTap == null ? .4 : 1,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(colors: g),
              boxShadow: [BoxShadow(color: g.first.withOpacity(.4), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(i, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900))),
            ]),
          ),
        ),
      );

  // ───────────── ACTIVE ALERT TAB ─────────────
  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 120 + 16 * _pulse.value,
                height: 120 + 16 * _pulse.value,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green.withOpacity(.08 + .06 * _pulse.value),
                    border: Border.all(color: _green.withOpacity(.5), width: 2)),
                child: const Icon(Icons.radar, size: 56, color: _green),
              ),
            ),
            const SizedBox(height: 22),
            const Text('All clear', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('You are online and ready.\nA siren pop-up will appear the moment a nearby help seeker sends an SOS.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, height: 1.4)),
          ]),
        ),
      );

  Widget _alertTab() => AnimatedBuilder(
        animation: AlertService.I,
        builder: (_, __) {
          final s = AlertService.I.active;
          if (s == null) return _empty();
          final km = _km(s);
          final eta = km == null ? '—' : '${(km / 30 * 60).ceil().clamp(1, 999)} min';
          final art = sosArtwork(s);
          final time = '${s.time.hour.toString().padLeft(2, '0')}:${s.time.minute.toString().padLeft(2, '0')}';
          final phoneShown = !(s.doNotCall || s.phone.isEmpty);
          return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 30), children: [
            // 1 ── alert banner
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(colors: s.cancelled ? [const Color(0xFF14532D), const Color(0xFF0B2E1B)] : [const Color(0xFFB4001B), const Color(0xFF4A0612)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: (s.cancelled ? _green : _red).withOpacity(.25 + .25 * _pulse.value), blurRadius: 24, spreadRadius: 1)],
                ),
                child: child,
              ),
              child: Row(children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.16)),
                  child: Icon(s.cancelled ? Icons.verified_user : Icons.warning_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.cancelled ? 'USER IS SAFE' : 'NEW EMERGENCY ALERT',
                      style: const TextStyle(color: Colors.white, fontSize: 18.5, fontWeight: FontWeight.w900, letterSpacing: .6)),
                  const SizedBox(height: 3),
                  Text(s.cancelled ? 'This SOS was cancelled – no action needed.' : 'A user has triggered an SOS. Immediate assistance is required.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3)),
                ])),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _pill(s.highAlert ? 'CRITICAL' : 'URGENT', Colors.white),
                  const SizedBox(height: 6),
                  Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(_ago(s), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ]),
              ]),
            ),

            // 2 ── victim
            _panel(
              child: Row(children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF1F3FD6), Color(0xFF0A84FF)])),
                  child: const Icon(Icons.person, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('HELP SEEKER', style: TextStyle(color: _ice, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                  const SizedBox(height: 2),
                  Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.phone, size: 14, color: Colors.white54),
                    const SizedBox(width: 5),
                    Text(phoneShown ? '+91 ${s.phone}' : 'Phone hidden by user', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _pill(s.category, _red, i: Icons.shield),
                  const SizedBox(height: 6),
                  _pill('Location shared', _green, i: Icons.location_on),
                ]),
              ]),
            ),

            // 3 ── map
            _panel(
              pad: const EdgeInsets.all(10),
              child: Column(children: [
                if (s.lat != 0)
                  Stack(children: [
                    MiniMap(s.lat, s.lng, height: 200),
                    Positioned(left: 10, top: 10, child: _pill('LIVE LOCATION', _red, i: Icons.fiber_manual_record)),
                    Positioned(
                        right: 10,
                        top: 10,
                        child: GestureDetector(
                          onTap: () => navigateTo(s.lat, s.lng),
                          child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF0D1733), borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
                              child: const Icon(Icons.open_in_new, size: 18, color: Colors.white)),
                        )),
                    Positioned(
                        left: 10,
                        bottom: 10,
                        child: Row(children: [
                          _pill(km == null ? 'Locating you…' : '${km.toStringAsFixed(1)} km away', const Color(0xFF5CC8FF), i: Icons.near_me),
                          const SizedBox(width: 6),
                          _pill('ETA $eta', const Color(0xFFFFC53D), i: Icons.timer),
                        ])),
                  ])
                else
                  const Padding(
                      padding: EdgeInsets.all(26), child: Text('Exact location not available – call the user.', style: TextStyle(color: Colors.white60))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
                  child: Row(children: [
                    const Icon(Icons.location_on, color: _red, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${s.lat.toStringAsFixed(4)}° N,  ${s.lng.toStringAsFixed(4)}° E',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      if (s.address.isNotEmpty) Text('Near ${s.address}', style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
                    ])),
                  ]),
                ),
              ]),
            ),

            // 4 ── emergency details
            _panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _h('Emergency details', i: Icons.assignment_late, c: _red),
                Row(children: [
                  if (art != null) ...[
                    ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(art, width: 58, height: 58, fit: BoxFit.cover)),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: Text(s.type, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
                ]),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
                  child: Text(s.desc.isEmpty ? 'No description provided.' : '“${s.desc}”',
                      style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4, fontStyle: FontStyle.italic)),
                ),
                const SizedBox(height: 10),
                if (s.tags.isEmpty)
                  const Text('Injuries / tags: Not mentioned', style: TextStyle(color: Colors.white54, fontSize: 13))
                else
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final t in s.tags) _pill(t, const Color(0xFFFFC53D), i: Icons.label)]),
                for (final e in s.details.entries) _kv(e.key, e.value),
                if (s.stage >= 1 && s.photo != null && (s.photo!.startsWith('https://') || s.photo!.startsWith('http://')))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(s.photo!, headers: Api.I.authHeaders, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  ),
                if (s.stage >= 1 && s.audio != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                        onPressed: () async {
                          var path = s.audio!;
                          if (path.startsWith('http')) {
                            final f = await Api.I.downloadFile(path); // voice note stored on the server
                            if (f == null) return;
                            path = f;
                          }
                          AudioPlayer().play(DeviceFileSource(path));
                        },
                        icon: const Icon(Icons.graphic_eq, color: _ice),
                        label: const Text('Play voice note', style: TextStyle(color: _ice))),
                  ),
              ]),
            ),

            // 5 ── actions
            Row(children: [
              Expanded(child: _gradBtn(s.doNotCall ? 'Message only' : 'Call Victim', Icons.call, const [Color(0xFF22C55E), Color(0xFF0E8A3E)], phoneShown ? () => dial(s.phone) : null)),
              const SizedBox(width: 12),
              Expanded(child: _gradBtn('Navigate', Icons.navigation, const [Color(0xFF2D8CFF), Color(0xFF1F3FD6)], s.lat == 0 ? null : () => navigateTo(s.lat, s.lng))),
            ]),
            const SizedBox(height: 18),

            // 6 ── rescue status
            _panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _h('Rescue status', i: Icons.route),
                _stepper(s.stage),
                const SizedBox(height: 14),
                if (s.stage < 4 && !s.cancelled)
                  _gradBtn(const ['ACCEPT & RESPOND', 'MARK: ON THE WAY', 'MARK: ARRIVED', 'MARK: ASSISTANCE PROVIDED'][s.stage],
                      s.stage == 3 ? Icons.check_circle : Icons.bolt, const [Color(0xFFFF4D5E), Color(0xFFD1001F)], () => _advance(s)),
                if (s.stage >= 4)
                  const Row(children: [
                    Icon(Icons.verified, color: _green),
                    SizedBox(width: 8),
                    Expanded(child: Text('Assistance provided – thank you, hero!', style: TextStyle(color: _green, fontWeight: FontWeight.w800))),
                  ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.groups, color: _ice),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.responder ?? 'Not yet assigned', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                  Text('ETA $eta', style: const TextStyle(color: Color(0xFFFFC53D), fontWeight: FontWeight.w900)),
                ]),
              ]),
            ),
          ]);
        },
      );

  void _advance(Sos s) {
    final next = s.stage + 1;
    AlertService.I.setStage(s, next, responder: s.responder ?? '${AppState.I.name} (Responder)');
    if (next == 4) {
      AppState.I.addResponse({
        'type': s.type,
        'category': s.category,
        'name': s.name,
        'address': s.address,
        'time': DateTime.now().toIso8601String(),
      });
    }
  }

  Widget _stepper(int stage) {
    const labels = ['SOS Received', 'Assigned', 'On the Way', 'Arrived', 'Provided'];
    const icons = [Icons.sos, Icons.groups, Icons.directions_car, Icons.location_on, Icons.check_circle];
    return Row(children: [
      for (var i = 0; i < 5; i++)
        Expanded(
            child: Column(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= stage ? (i == 0 ? _red : _green) : Colors.white.withOpacity(.07),
              border: Border.all(color: i <= stage ? Colors.transparent : _line),
              boxShadow: i == stage ? [BoxShadow(color: (i == 0 ? _red : _green).withOpacity(.6), blurRadius: 12)] : null,
            ),
            child: Icon(icons[i], size: 17, color: i <= stage ? Colors.white : Colors.white38),
          ),
          const SizedBox(height: 5),
          Text(labels[i],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: i <= stage ? FontWeight.w800 : FontWeight.w400, color: i <= stage ? Colors.white : Colors.white38)),
        ])),
    ]);
  }

  // ───────────── MAP TAB ─────────────
  Widget _mapTab() => AnimatedBuilder(
        animation: AlertService.I,
        builder: (_, __) {
          final s = AlertService.I.active;
          final me = _me == null ? null : LatLng(_me!.latitude, _me!.longitude);
          final them = s == null || s.lat == 0 ? null : LatLng(s.lat, s.lng);
          final centre = them ?? me ?? const LatLng(11.6234, 92.7265);
          return FlutterMap(
            options: MapOptions(initialCenter: centre, initialZoom: 14),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.resqmitra.app'),
              if (me != null && them != null) PolylineLayer(polylines: [Polyline(points: [me, them], color: const Color(0xFF1F3FD6), strokeWidth: 4)]),
              MarkerLayer(markers: [
                if (me != null) Marker(point: me, width: 48, height: 48, child: const Icon(Icons.navigation, color: Color(0xFF1F3FD6), size: 40)),
                if (them != null) Marker(point: them, width: 48, height: 48, child: const Icon(Icons.location_on, color: Colors.red, size: 46)),
              ]),
            ],
          );
        },
      );

  // ───────────── TEAMS TAB ─────────────
  Widget _teamsTab() => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.06), border: Border.all(color: _line)),
              child: const Icon(Icons.groups, size: 50, color: _ice),
            ),
            const SizedBox(height: 18),
            const Text('Response teams', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Teams will appear here once your profile is verified and linked to a rescue organisation.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, height: 1.4)),
          ]),
        ),
      );

  // ───────────── SETTINGS TAB ─────────────
  Widget _setTile(IconData i, String t, String sub, VoidCallback onTap) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
        child: ListTile(
          leading: Icon(i, color: _ice),
          title: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          subtitle: Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          onTap: onTap,
        ),
      );

  Widget _settingsTab() => ValueListenableBuilder<bool>(
        valueListenable: AppState.I.online,
        builder: (_, on, __) => ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
            child: SwitchListTile(
                activeColor: _green,
                title: const Text('Online – receive SOS alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                subtitle: const Text('Offline = no siren pop-ups from help seekers', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
                value: on,
                onChanged: AppState.I.setOnline),
          ),
        ]),
      );

  // ───────────── scaffold ─────────────
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF040817),
          foregroundColor: Colors.white,
          toolbarHeight: 68,
          titleSpacing: 0,
          flexibleSpace: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF040817), Color(0xFF14090F)], begin: Alignment.centerLeft, end: Alignment.centerRight))),
          title: const Row(children: [
            Icon(Icons.shield, color: _red, size: 34),
            SizedBox(width: 8),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('RESQ-MITRA', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text('Responder Dashboard', style: TextStyle(color: Color(0xFF5CC8FF), fontSize: 12)),
            ]),
          ]),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: AppState.I.online,
              builder: (_, on, __) => GestureDetector(
                onTap: () => AppState.I.setOnline(!on),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: (on ? _green : Colors.grey).withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: on ? _green : Colors.grey)),
                  child: Row(children: [
                    Icon(Icons.circle, size: 10, color: on ? _green : Colors.grey),
                    const SizedBox(width: 6),
                    Text(on ? 'Online' : 'Offline', style: TextStyle(color: on ? _green : Colors.grey, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
            AnimatedBuilder(
                animation: AlertService.I,
                builder: (_, __) => Padding(
                      padding: const EdgeInsets.only(left: 10, right: 14),
                      child: Badge(
                          isLabelVisible: AlertService.I.active != null && !AlertService.I.active!.cancelled,
                          label: const Text('1'),
                          child: const Icon(Icons.notifications_none, size: 30)),
                    )),
          ],
        ),
        body: IndexedStack(index: _tab, children: [_alertTab(), _mapTab(), _teamsTab(), _settingsTab()]),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(color: Color(0xFF040817), border: Border(top: BorderSide(color: _line))),
          child: SafeArea(
            child: BottomNavigationBar(
              backgroundColor: const Color(0xFF040817),
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              selectedItemColor: _tab == 0 ? _red : Colors.white,
              unselectedItemColor: Colors.white54,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Active Alert'),
                BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
                BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Teams'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          ),
        ),
      );
}
