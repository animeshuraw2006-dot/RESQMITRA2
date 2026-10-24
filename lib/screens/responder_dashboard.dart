import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'appreciate.dart';

class ResponderDashboard extends StatefulWidget {
  const ResponderDashboard({super.key});
  @override
  State<ResponderDashboard> createState() => _ResponderDashboardState();
}

class _ResponderDashboardState extends State<ResponderDashboard> {
  int _tab = 0;
  Position? _me;
  StreamSubscription<Position>? _pos;

  @override
  void initState() {
    super.initState();
    _startTracking();
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
    _pos?.cancel();
    SirenService.stop();
    super.dispose();
  }

  double? _km(Sos s) => _me == null
      ? null
      : Geolocator.distanceBetween(_me!.latitude, _me!.longitude, s.lat, s.lng) / 1000;

  // ── tabs ──
  Widget _alertTab() => AnimatedBuilder(
        animation: AlertService.I,
        builder: (_, __) {
          final s = AlertService.I.active;
          if (s == null) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.notifications_none, size: 70, color: C.grey),
                      SizedBox(height: 10),
                      Text('No active alerts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      SizedBox(height: 6),
                      Text('Stay Online. A siren will sound when a nearby help seeker sends an SOS.', textAlign: TextAlign.center),
                    ])));
          }
          final km = _km(s);
          final eta = km == null ? '—' : '${(km / 30 * 60).ceil().clamp(1, 999)} mins';
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 52),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('NEW EMERGENCY ALERT', style: TextStyle(color: Colors.red, fontSize: 19, fontWeight: FontWeight.w900)),
                Text(s.cancelled ? 'This SOS was cancelled – the user is safe.' : 'A user has triggered an SOS. Immediate assistance is required.'),
              ])),
              Column(children: [
                const Text('● Critical', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
                Text('${s.time.hour.toString().padLeft(2, '0')}:${s.time.minute.toString().padLeft(2, '0')}'),
              ]),
            ]),
            const Divider(height: 28),
            Row(children: [
              const CircleAvatar(radius: 34, backgroundColor: C.field, child: Icon(Icons.person, size: 40, color: C.navy)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('User Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text(s.name),
                Text(s.doNotCall || s.phone.isEmpty ? 'Phone hidden' : '+91 ${s.phone}'),
                const Text('Location shared'),
              ])),
              Text(s.category, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 14),
            if (s.lat != 0) MiniMap(s.lat, s.lng, height: 170),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s.lat.toStringAsFixed(4)}° N, ${s.lng.toStringAsFixed(4)}° E', style: const TextStyle(fontWeight: FontWeight.w800)),
                if (s.address.isNotEmpty) Text('(Near ${s.address})', style: const TextStyle(fontSize: 12)),
                if (km != null) Text('${km.toStringAsFixed(1)} km away', style: const TextStyle(fontSize: 12, color: C.grey)),
              ])),
            ]),
            const SizedBox(height: 14),
            const Text('Emergency Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Type: ${s.type}'),
            Text('Description: ${s.desc.isEmpty ? "Not provided" : s.desc}'),
            Text('Injuries / tags: ${s.tags.isEmpty ? "Not mentioned" : s.tags.join(", ")}'),
            for (final e in s.details.entries) Text('${e.key}: ${e.value}'),
            if (s.photo != null &&
                (Uri.tryParse(s.photo!)?.hasAbsolutePath == true) &&
                (s.photo!.startsWith('https://') || s.photo!.startsWith('http://')))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    s.photo!,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if (s.audio != null)
              TextButton.icon(
                  onPressed: () => AudioPlayer().play(DeviceFileSource(s.audio!)),
                  icon: const Icon(Icons.graphic_eq), label: const Text('Play voice note')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: C.ok, foregroundColor: Colors.white, minimumSize: const Size(0, 54)),
                      onPressed: s.doNotCall || s.phone.isEmpty ? null : () => dial(s.phone),
                      icon: const Icon(Icons.call),
                      label: Text(s.doNotCall ? 'Do not call (message only)' : 'Call Victim'))),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: C.blue, foregroundColor: Colors.white, minimumSize: const Size(0, 54)),
                      onPressed: () => navigateTo(s.lat, s.lng),
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate'))),
            ]),
            const SizedBox(height: 16),
            const Text('Rescue Status', style: TextStyle(fontWeight: FontWeight.w900, color: C.royal)),
            const SizedBox(height: 10),
            StatusStepper(s.stage),
            const SizedBox(height: 12),
            if (s.stage < 4 && !s.cancelled)
              PButton(const ['Accept & respond', 'Mark: On the way', 'Mark: Arrived', 'Mark: Assistance provided'][s.stage],
                  color: C.royal,
                  onTap: () => AlertService.I.setStage(s, s.stage + 1, responder: s.responder ?? '${AppState.I.name} (Responder)')),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.groups, color: C.royal),
              const SizedBox(width: 8),
              Expanded(child: Text(s.responder ?? 'Not yet assigned', style: const TextStyle(fontWeight: FontWeight.w800))),
              Text('ETA $eta', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ]);
        },
      );

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
              if (me != null && them != null)
                PolylineLayer(polylines: [Polyline(points: [me, them], color: C.royal, strokeWidth: 4)]),
              MarkerLayer(markers: [
                if (me != null)
                  Marker(point: me, width: 48, height: 48, child: const Icon(Icons.navigation, color: C.royal, size: 40)),
                if (them != null)
                  Marker(point: them, width: 48, height: 48, child: const Icon(Icons.location_on, color: Colors.red, size: 46)),
              ]),
            ],
          );
        },
      );

  Widget _teamsTab() => const Center(
      child: Padding(
          padding: EdgeInsets.all(30),
          child: Text('Response teams will appear here once your profile is verified and linked to a rescue organisation.', textAlign: TextAlign.center)));

  Future<void> _simulate() async {
    final p = _me ?? await LocationService.current();
    final lat = (p?.latitude ?? 11.6234) + 0.01, lng = (p?.longitude ?? 92.7265) + 0.01;
    final s = Sos(
      id: 'demo${DateTime.now().millisecondsSinceEpoch}',
      userId: 'demo-user',
      category: 'Women SOS',
      type: 'Immediate Danger',
      name: 'Demo user',
      phone: '9876543210',
      lat: lat,
      lng: lng,
      desc: 'I am being followed. Near the bus stop. Please help.',
    );
    AlertService.I.receive(s); // Home screen plays the siren for online responders
    if (AppState.I.online.value) SirenService.alertBeep();
    setState(() => _tab = 0);
  }

  Widget _settingsTab() => ValueListenableBuilder<bool>(
        valueListenable: AppState.I.online,
        builder: (_, on, __) => ListView(padding: const EdgeInsets.all(16), children: [
          SwitchListTile(
              title: const Text('Online – receive SOS alerts', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Offline = no notifications from help seekers'),
              value: on,
              onChanged: AppState.I.setOnline),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Simulate incoming SOS (demo)'),
              subtitle: const Text('Test the siren + responder flow on one phone'),
              onTap: _simulate),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          toolbarHeight: 66,
          titleSpacing: 0,
          title: const Row(children: [
            Icon(Icons.shield, color: Colors.redAccent, size: 34),
            SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('RESQ-MITRA', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
              Text('Responder Dashboard', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 12)),
            ]),
          ]),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: AppState.I.online,
              builder: (_, on, __) => GestureDetector(
                onTap: () => AppState.I.setOnline(!on),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: on ? Colors.greenAccent : Colors.grey)),
                  child: Row(children: [
                    Icon(Icons.circle, size: 10, color: on ? Colors.greenAccent : Colors.grey),
                    const SizedBox(width: 6),
                    Text(on ? 'Online' : 'Offline', style: TextStyle(color: on ? Colors.greenAccent : Colors.grey, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
            AnimatedBuilder(
                animation: AlertService.I,
                builder: (_, __) => Padding(
                      padding: const EdgeInsets.only(left: 8, right: 12),
                      child: Badge(
                          isLabelVisible: AlertService.I.active != null,
                          label: const Text('1'),
                          child: const Icon(Icons.notifications_none, size: 30)),
                    )),
          ],
        ),
        body: IndexedStack(index: _tab, children: [
          _alertTab(),
          _mapTab(),
          _teamsTab(),
          _settingsTab(),
          const AppreciateBody(),
        ]),
        bottomNavigationBar: Container(
          color: Colors.black,
          child: SafeArea(
            child: BottomNavigationBar(
              backgroundColor: Colors.black,
              type: BottomNavigationBarType.fixed,
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              selectedItemColor: _tab == 0 ? Colors.red : Colors.white,
              unselectedItemColor: Colors.white70,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Active Alert'),
                BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
                BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Teams'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Feedback'),
              ],
            ),
          ),
        ),
      );
}
