import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'responder_screen.dart';
import 'victim_screen.dart';
import 'sos_selection_screen.dart';

const _navy = Color(0xFF123B58);
const _blue = Color(0xFF2698D0);
const _pale = Color(0xFFEAF7FD);
const _red = Color(0xFFEC1027);

/// ResQMitra dashboard based on the supplied home-screen reference.
/// Hardware controls are clearly labelled as UI-only until native integrations
/// are added; SOS requests use the existing VictimScreen workflow.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _sirenEnabled = false;
  bool _flashEnabled = false;
  int _tab = 0;

  Future<void> _openHelp({bool highAlert = false}) async {
    if (highAlert) {
      var remaining = 5;
      Timer? countdown;
      var countdownStarted = false;
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            if (!countdownStarted) {
              countdownStarted = true;
              // Keep 5 visible for the full first second. The first decrement
              // happens only after one complete second has elapsed.
              countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (!dialogContext.mounted) {
                  timer.cancel();
                  return;
                }
                if (remaining > 0) {
                  setDialogState(() => remaining--);
                }
                if (remaining == 0) timer.cancel();
              });
            }
            return AlertDialog(
              icon: const Icon(Icons.warning_rounded, color: _red, size: 42),
              title: const Text('HIGH ALERT SOS'),
              content: Text(remaining > 0
                  ? 'Immediate danger? Continue to the SOS form in $remaining seconds. You can cancel now.'
                  : 'Continue to the emergency request form?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  onPressed: remaining == 0
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  style: FilledButton.styleFrom(backgroundColor: _red),
                  child: const Text('CONTINUE'),
                ),
              ],
            );
          },
        ),
      );
      countdown?.cancel();
      if (proceed != true || !mounted) return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SosSelectionScreen()));
  }

  Future<void> _call112() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please call 112 directly if you are in immediate danger.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pale,
      body: SafeArea(
        child: _tab == 0 ? _homeBody() : _tabPage(),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFD9F0FC),
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'HOME'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'MAP'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'HISTORY'),
          NavigationDestination(icon: Icon(Icons.military_tech_outlined), label: 'BADGES'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'PROFILE'),
        ],
      ),
    );
  }

  Widget _homeBody() => LayoutBuilder(builder: (context, constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Expanded(child: Text('RESQ-MITRA', style: TextStyle(color: _navy, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: .2))),
              _headerIcon(Icons.badge_outlined, 'Profile', () => setState(() => _tab = 4)),
              const SizedBox(width: 8),
              _headerIcon(Icons.volunteer_activism_rounded, 'Volunteer', () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ResponderScreen()))),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              _quickControl(icon: Icons.notifications_active_rounded, label: _sirenEnabled ? 'SIREN UI ON' : 'SIREN', active: _sirenEnabled, color: _red, onTap: () => setState(() => _sirenEnabled = !_sirenEnabled)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => setState(() => _flashEnabled = !_flashEnabled),
                icon: Icon(Icons.flashlight_on_rounded, color: _flashEnabled ? Colors.orange.shade800 : const Color(0xFF159B95)),
                label: Text(_flashEnabled ? 'FLASH ON*' : 'FLASHLIGHT*', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF159B95))),
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .8), side: const BorderSide(color: Color(0xFFD0E4EC)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ]),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF8EF), Color(0xFFE5FAF4)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: _navy.withValues(alpha: .06), blurRadius: 18, offset: const Offset(0, 6))]),
              child: Column(children: [
                const Text('HELP IS ONE TAP AWAY', textAlign: TextAlign.center, style: TextStyle(color: _navy, fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openHelp(highAlert: true),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17), decoration: BoxDecoration(color: const Color(0xFF9E0715), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFF5967), width: 1.5), boxShadow: [BoxShadow(color: _red.withValues(alpha: .23), blurRadius: 16, spreadRadius: 1)]), child: const Row(children: [Icon(Icons.warning_rounded, color: Colors.white, size: 36), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('HIGH ALERT SOS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('Immediate danger · 5-second confirmation · no questions', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.35))])), Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32)])),
                ),
                const SizedBox(height: 28),
                Semantics(button: true, label: 'Open standard SOS emergency form', child: GestureDetector(
                  onTap: () => _openHelp(),
                  child: Container(width: constraints.maxWidth.clamp(0, 380).toDouble(), height: constraints.maxWidth < 390 ? 240 : 300, decoration: BoxDecoration(shape: BoxShape.circle, color: _red, boxShadow: [BoxShadow(color: _red.withValues(alpha: .25), blurRadius: 28, spreadRadius: 5)]), alignment: Alignment.center, child: const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
                )),
                const SizedBox(height: 25),
                const Text('Choose an emergency type for standard SOS. High Alert opens the immediate-danger flow after confirmation.', textAlign: TextAlign.center, style: TextStyle(color: _navy, fontSize: 15, height: 1.5)),
              ]),
            ),
            const SizedBox(height: 18),
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), border: Border.all(color: _blue, width: 1.4), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.call_rounded, color: _blue, size: 38), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('HELP LINE', style: TextStyle(color: _blue, fontSize: 16, fontWeight: FontWeight.w900)), Text('Emergency helpline · India: 112', style: TextStyle(color: Colors.black87, fontSize: 13))])), FilledButton(onPressed: _call112, style: FilledButton.styleFrom(backgroundColor: _blue), child: const Text('CALL 112'))]),
            const SizedBox(height: 8),
            const Text('*Siren and flashlight controls are interface previews until device hardware/audio permissions are integrated.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black54)),
          ]),
        ),
      ),
    );
  });

  Widget _headerIcon(IconData icon, String tooltip, VoidCallback onTap) => IconButton.filledTonal(tooltip: tooltip, onPressed: onTap, icon: Icon(icon, color: _navy, size: 25), style: IconButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))));

  Widget _quickControl({required IconData icon, required String label, required bool active, required Color color, required VoidCallback onTap}) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: active ? color : const Color(0xFFD0E4EC), width: 1.4)), child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 2), Text(label, style: const TextStyle(color: _navy, fontSize: 11, fontWeight: FontWeight.w800))])));

  Widget _tabPage() {
    final titles = ['HOME', 'MAP', 'HISTORY', 'BADGES', 'PROFILE'];
    final icons = [Icons.home_rounded, Icons.map_outlined, Icons.history_rounded, Icons.military_tech_outlined, Icons.person_outline_rounded];
    final descriptions = ['Your emergency dashboard.', 'Map integration depends on configured map keys and location permissions.', 'Your incident history will appear here when incident history is connected.', 'Community impact badges will appear here as verified activities are recorded.', 'Profile details and account settings.'];
    return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icons[_tab], size: 56, color: _blue), const SizedBox(height: 14), Text(titles[_tab], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _navy)), const SizedBox(height: 8), Text(descriptions[_tab], textAlign: TextAlign.center, style: const TextStyle(color: _navy, height: 1.5)), if (_tab == 1) const Padding(padding: EdgeInsets.only(top: 16), child: Text('For immediate danger in India, call 112.', style: TextStyle(fontWeight: FontWeight.bold, color: _red)))])));
  }
}
