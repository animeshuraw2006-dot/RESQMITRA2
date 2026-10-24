import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = AppState.I.profile;
    bool has(String k) => (p[k] ?? '').toString().isNotEmpty;
    final rows = <(String, String)>[
      ('Full Name', has('name') ? 'v' : 'p'),
      ('Profile Photograph', has('photo') ? 'v' : 'p'),
      ('Mobile Number', p['mobileV'] == true ? 'v' : 'p'),
      ('Email Address', p['emailV'] == true ? 'v' : 'p'),
      ('Permanent Address', has('phouse') ? 'v' : 'p'),
      ('GPS Location', p['lat'] != null ? 'v' : 'p'),
      ('Emergency Contact 1', has('c0phone') ? 'v' : 'p'),
      ('Emergency Contact 2', has('c1phone') ? 'v' : 'p'),
      ('Identity Verification', has('docPhoto') ? 'p' : 'p'),
      ('Medical Information', (has('blood') || has('allergies') || has('conditions')) ? 'v' : 'n'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Summary')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final r in rows)
          ListTile(
            title: Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(r.$2 == 'v' ? Icons.check_circle : r.$2 == 'p' ? Icons.schedule : Icons.info,
                  color: r.$2 == 'v' ? C.ok : r.$2 == 'p' ? C.warn : C.grey, size: 20),
              const SizedBox(width: 4),
              Text(r.$2 == 'v' ? 'Provided' : r.$2 == 'p' ? 'Pending' : 'Not Provided',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: r.$2 == 'v' ? C.ok : r.$2 == 'p' ? C.warn : C.grey)),
            ]),
          ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFE8F6F5), borderRadius: BorderRadius.circular(10)),
          child: const Text('You can still send an SOS even if some verifications are pending.'),
        ),
      ]),
    );
  }
}
