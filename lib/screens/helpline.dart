import 'package:flutter/material.dart';
import '../services.dart';
import '../theme.dart';

class HelplineScreen extends StatelessWidget {
  const HelplineScreen({super.key});
  static const _list = [
    ('National Emergency Number', '112', Icons.sos, Colors.red),
    ('Police', '100', Icons.local_police, C.royal),
    ('Fire', '101', Icons.local_fire_department, Colors.deepOrange),
    ('Ambulance', '102', Icons.emergency, Colors.red),
    ('Emergency Ambulance', '108', Icons.medical_services, Colors.red),
    ('Women Helpline', '1091', Icons.face_3, Colors.pink),
    ('Women Helpline (Domestic Abuse)', '181', Icons.shield, Colors.pink),
    ('Child Helpline (CHILDLINE)', '1098', Icons.child_care, Colors.amber),
    ('Disaster Management (NDMA)', '1078', Icons.flood, C.blue),
    ('Road Accident Emergency', '1073', Icons.car_crash, Colors.red),
    ('Highway Helpline (NHAI)', '1033', Icons.add_road, C.navy),
    ('Coast Guard (sea distress)', '1554', Icons.sailing, C.blue),
    ('Cyber Crime', '1930', Icons.security, Colors.indigo),
    ('Tele-MANAS (mental health)', '14416', Icons.psychology, C.both),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Emergency Helplines')),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final (name, number, icon, color) = _list[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: C.cyan)),
              child: Row(children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
                  Text(number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ])),
                InkWell(
                  onTap: () => dial(number),
                  child: const CircleAvatar(backgroundColor: C.ok, child: Icon(Icons.call, color: Colors.white)),
                ),
              ]),
            );
          },
        ),
      );
}
