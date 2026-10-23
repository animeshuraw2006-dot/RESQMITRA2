import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_header.dart';
import 'sos_screen.dart';
import 'responder_requests_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.role});
  final String role;

  bool get _hasHelpSeeker => role == 'helpSeeker' || role == 'both';
  bool get _hasResponder => role == 'responder' || role == 'both';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RESQ-MITRA'), actions: [
        IconButton(tooltip: 'Profile', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), icon: const Icon(Icons.account_circle_outlined)),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BrandHeader(compact: true),
          const SizedBox(height: 16),
          const Text('Together, we save lives.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 20),
          if (_hasHelpSeeker) Card(
            color: const Color(0xFFFFF0F0),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                const Icon(Icons.sos, color: Colors.red, size: 50),
                const Text('Need help right now?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy)),
                const SizedBox(height: 8),
                const Text('Create an emergency request. This starter saves a local demo request; it does not contact emergency services.', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(52)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen())),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Create SOS Request'),
                ),
              ]),
            ),
          ),
          if (_hasResponder) Card(
            color: const Color(0xFFE8F8F0),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                const Icon(Icons.volunteer_activism, color: AppColors.green, size: 44),
                const Text('Responder area', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy)),
                const SizedBox(height: 8),
                const Text('View sample requests and explore the responder workflow. Requests are demo data until a backend is connected.', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderRequestsScreen())),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('View Requests'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          const Card(child: ListTile(leading: Icon(Icons.verified_user, color: AppColors.green), title: Text('Safety reminder'), subtitle: Text('For immediate danger, contact local emergency services. This app starter is not a substitute for emergency services.'))),
        ],
      ),
    );
  }
}
