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

  void _cancel() {
    AlertService.I.cancel(widget.sos);
    SmsService.toContacts('ResQMitra: ${AppState.I.name} is SAFE. The earlier SOS was cancelled.');
    Navigator.of(context).popUntil((r) => r.isFirst);
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
              OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppreciateScreen())),
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  label: const Text('Help received – thank your responder')),
              TextButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Back to home')),
            ]);
          },
        ),
      );
}
