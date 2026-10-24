import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'permissions.dart';

class SuccessScreen extends StatelessWidget {
  final String role;
  const SuccessScreen({super.key, required this.role});
  @override
  Widget build(BuildContext context) {
    final rescuer = role != 'seeker';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Image.asset('assets/logo.jpeg', height: 130),
            const SizedBox(height: 20),
            const CircleAvatar(radius: 34, backgroundColor: C.ok, child: Icon(Icons.check, size: 44, color: Colors.white)),
            const SizedBox(height: 18),
            Text(rescuer ? 'Application Submitted!' : 'Registration Successful!',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.navy)),
            const SizedBox(height: 8),
            const Text('Welcome to ResQ-Mitra.\nYour account has been created successfully.', textAlign: TextAlign.center),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: C.field, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
              child: Text(
                  rescuer
                      ? 'Our team will verify your details and documents. You can start receiving SOS alerts once your profile is verified.'
                      : 'You are now a verified Help Seeker and can request assistance whenever you need it.',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            ),
            const Spacer(),
            PButton('Go to Home', icon: Icons.home,
                onTap: () => Navigator.pushAndRemoveUntil(
                    context, MaterialPageRoute(builder: (_) => const PermissionsScreen()), (r) => false)),
            const SizedBox(height: 10),
            const Text('Together, We Save Lives.', style: TextStyle(color: C.royal, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
