import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key, required this.role});
  final String role;

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _service = PermissionService();
  final Map<String, String> _states = {};

  Future<void> _request(String key) async {
    try {
      final status = switch (key) {
        'Location' => await _service.requestLocation(),
        'Notifications' => await _service.requestNotifications(),
        'Contacts' => await _service.requestContacts(),
        'Microphone' => await _service.requestMicrophone(),
        'Camera' => await _service.requestCamera(),
        _ => null,
      };
      if (status != null) {
        setState(() => _states[key] = status.isGranted || status.isLimited ? 'Enabled' : 'Not enabled');
      } else {
        setState(() => _states[key] = 'Use when needed');
      }
    } catch (_) {
      setState(() => _states[key] = 'Unavailable on this device');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _PermissionInfo('Location', 'Help responders find the incident location.', Icons.location_on, const Color(0xFFFFE8EF)),
      _PermissionInfo('Notifications', 'Receive emergency requests and important updates.', Icons.notifications_active, const Color(0xFFE0F3FF)),
      _PermissionInfo('Phone / Calling', 'Open the dialler to contact helplines or trusted people.', Icons.call, const Color(0xFFDDF8F0)),
      _PermissionInfo('Contacts', 'Choose trusted people for emergency contacts.', Icons.contacts, const Color(0xFFFFF4CD)),
      _PermissionInfo('Microphone', 'Use audio features when you choose to use them.', Icons.mic, const Color(0xFFF0E5FF)),
      _PermissionInfo('Camera', 'Capture images when reporting an incident.', Icons.camera_alt, const Color(0xFFE0F3FF)),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('App Permissions')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Icon(Icons.shield_outlined, size: 76, color: AppColors.blue),
          const Text('Allow App Permissions', textAlign: TextAlign.center, style: TextStyle(color: AppColors.navy, fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('To help you stay safe and connect with assistance, RESQ-MITRA may need access to certain features on your phone.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 20),
          ...items.map((item) => Card(
            color: item.color,
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              leading: CircleAvatar(backgroundColor: Colors.white, child: Icon(item.icon, color: AppColors.navy)),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('${item.description}${_states[item.title] == null ? '' : '\nStatus: ${_states[item.title]}'}'),
              ),
              trailing: IconButton(
                tooltip: 'Set up ${item.title}',
                onPressed: () => _request(item.title),
                icon: const Icon(Icons.arrow_forward, color: AppColors.navy),
              ),
            ),
          )),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Continue', onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(role: widget.role)))),
          TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(role: widget.role))), child: const Text('Not now')),
          const Text('You can manage permissions later in Android Settings. Optional permissions can be declined.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _PermissionInfo {
  const _PermissionInfo(this.title, this.description, this.icon, this.color);
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
