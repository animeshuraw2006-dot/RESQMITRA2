import 'package:flutter/material.dart';
import '../services.dart';
import '../theme.dart';

class AppreciateScreen extends StatelessWidget {
  const AppreciateScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Appreciate Your Responder')),
        body: const AppreciateBody(),
      );
}

class AppreciateBody extends StatefulWidget {
  const AppreciateBody({super.key});
  @override
  State<AppreciateBody> createState() => _AppreciateBodyState();
}

class _AppreciateBodyState extends State<AppreciateBody> {
  String _thanks = '', _feedback = '';
  String? _badge;
  static const _badges = ['Life Saver', 'Hero', 'Quick Responder', 'Kind Heart', 'Guardian Angel'];

  Future<String?> _ask(String title) {
    final c = TextEditingController();
    return showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(title),
              content: TextField(controller: c, maxLines: 4, maxLength: 300),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Save')),
              ],
            ));
  }

  Widget _opt(IconData i, Color c, String t, String d, bool done, VoidCallback tap) => GestureDetector(
        onTap: tap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE3EAF8))),
          child: Row(children: [
            CircleAvatar(radius: 30, backgroundColor: c.withOpacity(.12), child: Icon(i, color: c, size: 32)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text(d, style: const TextStyle(color: C.grey)),
            ])),
            Icon(done ? Icons.check_circle : Icons.chevron_right, color: done ? C.ok : C.royal),
          ]),
        ),
      );

  void _submit() {
    if (_badge != null) AlertService.I.badges.add(_badge!);
    // TODO(backend): send thanks, badge and feedback to the responder's profile.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you! Your appreciation was sent.')));
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        const Row(children: [
          CircleAvatar(radius: 48, backgroundColor: Color(0xFFE8F4FB), child: Icon(Icons.local_police, size: 56, color: C.navy)),
          SizedBox(width: 14),
          Expanded(
              child: Text('Your responder was there when help was needed. Thank you for being a part of a safer community!',
                  style: TextStyle(fontSize: 16, color: C.royal))),
        ]),
        const SizedBox(height: 18),
        const Text('How would you like to acknowledge your responder?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _opt(Icons.volunteer_activism, Colors.orange, 'Thank Your Responder', 'Send a personal message of gratitude to your responder.', _thanks.isNotEmpty,
            () async { final r = await _ask('Thank your responder'); if (r != null) setState(() => _thanks = r); }),
        _opt(Icons.workspace_premium, C.royal, 'Give an Appreciation Badge', _badge ?? 'Recognise their service with a digital badge and make them feel valued.', _badge != null,
            () async {
          final b = await showModalBottomSheet<String>(
              context: context,
              builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    for (final b in _badges) ListTile(leading: const Icon(Icons.workspace_premium, color: C.royal), title: Text(b), onTap: () => Navigator.pop(context, b)),
                  ])));
          if (b != null) setState(() => _badge = b);
        }),
        _opt(Icons.rate_review, C.ok, 'Share Feedback', 'Tell us about your experience, suggest improvements or report any issues.', _feedback.isNotEmpty,
            () async { final r = await _ask('Share feedback'); if (r != null) setState(() => _feedback = r); }),
        const SizedBox(height: 6),
        SizedBox(height: 54, child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1FD6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _submit, icon: const Icon(Icons.send), label: const Text('Submit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () { if (Navigator.canPop(context)) Navigator.pop(context); }, child: const Text('Skip for Now')),
        const SizedBox(height: 10),
        const Center(child: Text('Together we make our communities safer.', style: TextStyle(color: C.grey))),
      ]);
}
