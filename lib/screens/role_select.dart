import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'registration.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});
  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String _role = 'both';

  Widget _opt(String id, String title, String sub, IconData icon, Color color) {
    final sel = _role == id;
    return GestureDetector(
      onTap: () => setState(() => _role = id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: sel && id == 'both' ? C.both : Colors.transparent, width: 2)),
        child: Row(children: [
          Icon(icon, size: 44, color: color),
          const SizedBox(width: 22),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            Text(sub, style: const TextStyle(fontSize: 16, color: Color(0xFF1B1B1B))),
          ])),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2.5)),
            child: sel
                ? Center(child: Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: color)))
                : null,
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(children: [
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choose your role',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.navy))),
              const SizedBox(height: 14),
              Image.asset('assets/logo.jpeg', height: 150),
              const SizedBox(height: 14),
              const Text('Join ResQMitra',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: C.navy)),
              const SizedBox(height: 8),
              const Text('Choose how you want to use ResQMitra.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF1B1B1B))),
              const SizedBox(height: 16),
              _opt('seeker', 'HELP SEEKER', 'Need assistance', Icons.shield_outlined, C.seeker),
              _opt('rescuer', 'AS RESCUER', 'Help others', Icons.person, C.rescuer),
              _opt('both', 'BOTH', 'Seek help and respond', Icons.groups, C.both),
              const SizedBox(height: 10),
              const Text('TOGETHER, WE SAVE LIVES.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.both)),
              const SizedBox(height: 22),
              PButton('CONTINUE',
                  color: C.blue,
                  radius: 22,
                  height: 58,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => RegistrationScreen(role: _role)))),
            ]),
          ),
        ),
      );
}
