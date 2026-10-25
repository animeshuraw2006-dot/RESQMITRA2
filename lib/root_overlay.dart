import 'dart:async';
import 'package:flutter/material.dart';
import 'avatar.dart';
import 'badges.dart';
import 'nav.dart';
import 'screens/alert_popup.dart';
import 'screens/badge_reveal.dart';
import 'screens/profile.dart';
import 'services.dart';
import 'state.dart';
import 'theme.dart';
import 'verify_items.dart';

/// Wraps the whole app:
///  • the constant floating PROFILE button (bottom-right)
///  • the SOS pop-up + siren for ONLINE responders (works on every screen)
///  • the glowing badge-reveal when a responder receives appreciation
class RootOverlay extends StatefulWidget {
  final Widget child;
  const RootOverlay({super.key, required this.child});
  @override
  State<RootOverlay> createState() => _RootOverlayState();
}

class _RootOverlayState extends State<RootOverlay> {
  StreamSubscription<Sos>? _sos;
  StreamSubscription<Appreciation>? _apr;

  @override
  void initState() {
    super.initState();
    _sos = AlertService.I.stream.listen(_onSos);
    _apr = AlertService.I.appreciations.listen(_onAppreciation);
  }

  @override
  void dispose() {
    _sos?.cancel();
    _apr?.cancel();
    super.dispose();
  }

  void _onSos(Sos s) {
    final a = AppState.I;
    if (!a.ready || !a.registered || s.userId == a.uid) return;
    if (!a.isRescuer || !a.online.value) return; // offline / seeker-only → silent
    showAlertPopup(s);
  }

  Future<void> _onAppreciation(Appreciation a) async {
    final st = AppState.I;
    if (!st.ready || !st.registered || !st.isRescuer) return;
    await st.receiveAppreciation(
        badge: a.badgeKey, from: a.from, message: a.message, feedback: a.feedback, rating: a.rating);
    final def = badgeByKey(a.badgeKey);
    if (def == null) return;
    navKey.currentState?.push(MaterialPageRoute(
        settings: const RouteSettings(name: '/reveal'),
        builder: (_) => BadgeRevealScreen(badge: def, from: a.from, message: a.message, rating: a.rating)));
  }

  static const _hidden = {'/siren', '/high', '/reveal', '/appreciate', '/confirm', '/blood'};

  bool get _fabVisible {
    final a = AppState.I;
    if (!a.ready || !a.registered || !a.homeReached) return false;
    if (AppNav.I.topIsPopup) return false;
    final n = AppNav.I.topName;
    if (n == null) return true;
    return !(n.startsWith('/profile') || _hidden.contains(n));
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding.bottom;
    return Stack(fit: StackFit.expand, children: [
      widget.child,
      AnimatedBuilder(
        animation: Listenable.merge([AppNav.I.tick, AppState.I]),
        builder: (_, __) {
          if (!_fabVisible) return const SizedBox.shrink();
          final lift = AppNav.I.topName == '/responder' ? 76.0 : 0.0;
          return Positioned(right: 14, bottom: 18 + lift + pad, child: const _ProfileFab());
        },
      ),
    ]);
  }
}

class _ProfileFab extends StatelessWidget {
  const _ProfileFab();
  @override
  Widget build(BuildContext context) {
    final p = AppState.I.profile;
    final img = avatarProvider(p);
    final pending = verificationItems().where((e) => !e.ok).length;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => navKey.currentState?.push(MaterialPageRoute(
            settings: const RouteSettings(name: '/profile'), builder: (_) => const ProfileScreen())),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: const LinearGradient(colors: [Color(0xFF0B1650), Color(0xFF1F3FD6)]),
              border: Border.all(color: Colors.white.withOpacity(.85), width: 1.6),
              boxShadow: [
                BoxShadow(color: C.royal.withOpacity(.55), blurRadius: 16, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF1ED6A4),
                backgroundImage: img,
                child: img == null
                    ? Text(initialsOf(AppState.I.name),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('PROFILE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.1)),
            ]),
          ),
          if (pending > 0)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: C.warn, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.6)),
                child: Text('$pending',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ),
        ]),
      ),
    );
  }
}
