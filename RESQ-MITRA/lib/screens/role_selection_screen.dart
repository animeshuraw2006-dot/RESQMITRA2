import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_header.dart';
import '../widgets/primary_button.dart';
import 'registration_wizard_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _role = 'both';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              children: [
                const Align(alignment: Alignment.centerLeft, child: Text('Choose your role', style: TextStyle(color: AppColors.navy, fontSize: 26, fontWeight: FontWeight.w900))),
                const SizedBox(height: 24),
                const BrandHeader(),
                const SizedBox(height: 20),
                const Text('Join ResQ-Mitra', textAlign: TextAlign.center, style: TextStyle(color: AppColors.navy, fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('One account. Multiple roles. Complete safety.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.muted)),
                const SizedBox(height: 24),
                _roleCard('helpSeeker', 'HELP SEEKER', 'Need assistance', Icons.shield_outlined, AppColors.blue),
                _roleCard('responder', 'AS RESPONDER', 'Help others', Icons.volunteer_activism_outlined, AppColors.green),
                _roleCard('both', 'BOTH', 'Seek help and respond', Icons.groups_2_outlined, AppColors.teal),
                const SizedBox(height: 16),
                const Text('TOGETHER, WE SAVE LIVES.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.teal, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Continue',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrationWizardScreen(role: _role))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String value, String title, String subtitle, IconData icon, Color color) {
    final selected = _role == value;
    return Card(
      color: selected ? color.withValues(alpha: .10) : Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _role = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black87)),
            ])),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: color),
          ]),
        ),
      ),
    );
  }
}
