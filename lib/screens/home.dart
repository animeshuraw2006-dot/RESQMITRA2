import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../nav.dart';
import '../services.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'helpline.dart';
import 'high_alert.dart';
import 'responder_dashboard.dart';
import 'siren_screen.dart';
import 'sos_select.dart';
import 'verification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AppState.I.markHome(); // shows the floating PROFILE button from now on
    // NOTE: the siren pop-up for new SOS alerts lives in RootOverlay, so it
    // works on every screen – not only here.
  }

  void _openResponder() {
    if (!AppState.I.isRescuer) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You registered as a Help Seeker. Register as Rescuer or Both to respond.')));
      return;
    }
    if (AppNav.I.isOnStack('/responder')) return;
    Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: '/responder'), builder: (_) => const ResponderDashboard()));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: AppState.I, builder: (_, __) => _scaffold(context));

  Widget _scaffold(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(children: [
              Row(children: [
                const Text('RESQ-MITRA', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.navy)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.badge_outlined, size: 30, color: C.navy),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: '/verification'), builder: (_) => const VerificationScreen()))),
                IconButton(
                    icon: const Icon(Icons.volunteer_activism, size: 30, color: C.navy),
                    tooltip: 'Responder mode',
                    onPressed: _openResponder),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: '/siren'), builder: (_) => const SirenScreen())),
                  child: Container(
                    width: 74, height: 74,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: C.cyan, width: 2)),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.crisis_alert, color: Colors.red, size: 34),
                      Text('SIREN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: C.navy)),
                    ]),
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: FlashService.on,
                  builder: (_, on, __) => GestureDetector(
                    onTap: FlashService.toggle,
                    child: Row(children: [
                      Icon(on ? Icons.flashlight_on : Icons.flashlight_off, color: C.both, size: 34),
                      const SizedBox(width: 6),
                      Text(on ? 'FLASH ON' : 'FLASH OFF',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.both)),
                    ]),
                  ),
                ),
              ]),
              if (AppState.I.isRescuer)
                ValueListenableBuilder<bool>(
                  valueListenable: AppState.I.online,
                  builder: (_, on, __) => Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                        color: (on ? C.ok : C.grey).withOpacity(.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: on ? C.ok : C.grey)),
                    child: Row(children: [
                      Icon(Icons.circle, size: 12, color: on ? C.ok : C.grey),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(on ? 'ONLINE – ready to respond to alerts' : 'OFFLINE – no responder alerts',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: on ? C.ok : C.grey))),
                      Switch(value: on, activeColor: C.ok, onChanged: AppState.I.setOnline),
                    ]),
                  ),
                ),
              const SizedBox(height: 14),
              const Text('HELP IS ONE TAP AWAY',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.navy)),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: '/high'), builder: (_) => const HighAlertScreen())),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: C.darkRed,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red, width: 2)),
                  child: const Row(children: [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 44),
                    SizedBox(width: 14),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('HIGH ALERT SOS', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                      Text('Immediate danger • 5-second countdown • no questions',
                          style: TextStyle(color: Colors.white, fontSize: 15)),
                    ])),
                    Icon(Icons.chevron_right, color: Colors.white, size: 34),
                  ]),
                ),
              ),
              Expanded(
                child: Center(
                  child: LayoutBuilder(builder: (_, b) {
                    final s = math.min(math.min(b.maxWidth, b.maxHeight) * 1.0, 340.0);
                    return PulsingSosButton(
                      size: s,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChooseSosScreen())),
                    );
                  }),
                ),
              ),
              const Text('Choose an emergency type for standard SOS.\nHigh Alert sends an immediate-danger request\nafter its 5-second countdown.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Color(0xFF0B3C99))),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelplineScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: C.cyan, width: 1.5)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.phone, color: C.blue, size: 36),
                      SizedBox(width: 12),
                      SizedBox(height: 44, child: VerticalDivider(color: C.cyan)),
                      SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('HELP LINE', style: TextStyle(color: C.seeker, fontWeight: FontWeight.w900, fontSize: 18)),
                        Text('Emergency helpline\nnumber', style: TextStyle(fontSize: 14)),
                      ]),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}
