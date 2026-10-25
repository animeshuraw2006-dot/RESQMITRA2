import 'dart:async';
import 'package:flutter/material.dart';
import '../services.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'appreciate.dart';

/// Shown after an SOS is sent: 10-second cancel window + live rescue status.
class SosSentScreen extends StatefulWidget {
  final Sos sos;
  const SosSentScreen({super.key, required this.sos});
  @override
  State<SosSentScreen> createState() => _SosSentScreenState();
}

class _SosSentScreenState extends State<SosSentScreen> {
  int _left = 10;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    AlertService.I.cancel(widget.sos);
    SmsService.toContacts('ResQMitra: ${AppState.I.name} is SAFE. The earlier SOS was cancelled.');
    if (!mounted) return;
    // "I AM SAFE" → offer to appreciate the rescuer (the ONLY place this screen opens from)
    final yes = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            const CircleAvatar(radius: 32, backgroundColor: Color(0xFFE5F7EC), child: Icon(Icons.verified_user, color: C.ok, size: 38)),
            const SizedBox(height: 12),
            const Text('Glad you are safe!', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: C.navy)),
            const SizedBox(height: 6),
            const Text('Would you like to appreciate the rescuer who helped you? A badge and a kind word mean the world to them.',
                textAlign: TextAlign.center, style: TextStyle(color: C.grey, height: 1.4)),
            const SizedBox(height: 18),
            PButton('APPRECIATE MY RESCUER', icon: Icons.favorite, color: C.royal, radius: 28, onTap: () => Navigator.pop(context, true)),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Maybe later')),
          ]),
        ),
      ),
    );
    if (!mounted) return;
    if (yes == true) {
      await Navigator.push(context,
          MaterialPageRoute(settings: const RouteSettings(name: '/appreciate'), builder: (_) => AppreciateScreen(sos: widget.sos)));
    }
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('SOS Sent'), automaticallyImplyLeading: false),
        body: AnimatedBuilder(
          animation: AlertService.I,
          builder: (_, __) {
            final s = widget.sos;
            return ListView(padding: const EdgeInsets.all(20), children: [
              const Center(child: CircleAvatar(radius: 36, backgroundColor: C.ok, child: Icon(Icons.check, color: Colors.white, size: 46))),
              const SizedBox(height: 14),
              Center(child: Text(s.cancelled ? 'SOS cancelled' : 'Help is being arranged', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.navy))),
              const SizedBox(height: 6),
              Center(child: Text('${s.category} • ${s.type}', style: const TextStyle(color: C.grey))),
              const SizedBox(height: 18),
              if (s.lat != 0) MiniMap(s.lat, s.lng, height: 150),
              const SizedBox(height: 18),
              const Text('Rescue Status', style: TextStyle(fontWeight: FontWeight.w900, color: C.navy)),
              const SizedBox(height: 10),
              StatusStepper(s.stage),
              if (s.responder != null) ...[
                const SizedBox(height: 12),
                Text('Responder: ${s.responder}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 24),
              if (!s.cancelled) PButton(_left > 0 ? 'CANCEL SOS — I AM SAFE (${_left}s)' : 'CLOSE SOS — I AM SAFE', color: Colors.red, radius: 30, onTap: _cancel),
              const SizedBox(height: 10),
              TextButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Back to home')),
              const SizedBox(height: 90),
            ]);
          },
        ),
      );
}
