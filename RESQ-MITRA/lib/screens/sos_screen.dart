import 'package:flutter/material.dart';
import '../services/emergency_service.dart';
import '../theme/app_colors.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String _category = 'General Emergency';
  bool _busy = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final id = await EmergencyService().createDemoRequest(category: _category, description: _description.text.trim());
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (_) => AlertDialog(
        title: const Text('Demo request saved'),
        content: Text('Local demo request #$id was saved. No responder or emergency service has been notified.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save request: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Request')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          const Icon(Icons.sos, color: Colors.red, size: 72),
          const Text('Request Assistance', textAlign: TextAlign.center, style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900, fontSize: 25)),
          const SizedBox(height: 8),
          const Text('This starter stores a local demo request only. It does not notify responders or call emergency services.', textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Emergency category'),
            items: const ['General Emergency', 'Women Emergency', 'Medical Emergency', 'Road Accident', 'Fire', 'Drug Abuse Concern', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _category = v ?? 'General Emergency'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Describe what happened (optional)', alignLabelWithHint: true),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _busy ? null : _submit,
            icon: const Icon(Icons.send),
            label: Text(_busy ? 'Saving…' : 'Save Demo Request'),
          ),
        ]),
      ),
    );
  }
}
