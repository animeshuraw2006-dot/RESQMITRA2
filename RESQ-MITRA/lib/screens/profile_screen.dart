import 'package:flutter/material.dart';
import '../services/profile_storage_service.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await ProfileStorageService().loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = value;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fields = Map<String, dynamic>.from(_profile?['fields'] as Map? ?? {});
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Icon(Icons.account_circle, size: 84, color: AppColors.blue),
              const Text('Your RESQ-MITRA Profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy)),
              const SizedBox(height: 12),
              Card(child: ListTile(title: const Text('Role'), subtitle: Text((_profile?['role'] ?? 'Not selected').toString()))),
              Card(child: ListTile(title: const Text('Registration status'), subtitle: Text((_profile?['registrationStatus'] ?? 'Not submitted').toString()))),
              Card(child: ListTile(title: const Text('Verification status'), subtitle: Text((_profile?['verificationStatus'] ?? 'Not verified').toString()))),
              const SizedBox(height: 8),
              const Text('Saved profile fields', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
              ...fields.entries.where((e) => !e.key.startsWith('skill_') && !e.key.startsWith('resource_')).map((e) => Card(child: ListTile(title: Text(e.key), subtitle: Text(e.value.toString())))),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await ProfileStorageService().clearProfile();
                  if (!mounted) return;
                  setState(() => _profile = null);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local demo profile cleared.')));
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear local demo profile'),
              ),
            ]),
    );
  }
}
