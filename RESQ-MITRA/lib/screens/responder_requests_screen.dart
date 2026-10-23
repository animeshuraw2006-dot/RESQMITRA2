import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ResponderRequestsScreen extends StatelessWidget {
  const ResponderRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = [
      ('Medical assistance', '0.8 km away', Icons.medical_services, Colors.red),
      ('Road accident', '1.6 km away', Icons.car_crash, Colors.orange),
      ('General assistance', '2.4 km away', Icons.support_agent, AppColors.blue),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Responder Requests')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(color: Color(0xFFFFF4D8), child: Padding(
            padding: EdgeInsets.all(14),
            child: Text('Sample requests only. These are not live incidents and must not be used for real-world dispatch. Connect a trusted backend before deployment.', style: TextStyle(color: AppColors.navy)),
          )),
          ...requests.map((r) => Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: r.$4.withValues(alpha: .12), child: Icon(r.$3, color: r.$4)),
              title: Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(r.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog<void>(context: context, builder: (_) => AlertDialog(
                title: Text(r.$1),
                content: const Text('Demo only: accepting this sample request does not contact a help seeker.'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
              )),
            ),
          )),
        ],
      ),
    );
  }
}
