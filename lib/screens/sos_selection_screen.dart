import 'package:flutter/material.dart';
import 'victim_screen.dart';

const _navy = Color(0xFF102E59);
const _page = Color(0xFFEEF6FF);

class _EmergencyOption {
  final String title;
  final IconData icon;
  final Color background;
  final Color accent;
  const _EmergencyOption(this.title, this.icon, this.background, this.accent);
}

const _general = <_EmergencyOption>[
  _EmergencyOption('Medical Emergency', Icons.medical_services_rounded, Color(0xFFFFE4EC), Color(0xFFE95B7E)),
  _EmergencyOption('Accident', Icons.car_crash_rounded, Color(0xFFDDF8E4), Color(0xFF55B875)),
  _EmergencyOption('Fire', Icons.local_fire_department_rounded, Color(0xFFFFEFD4), Color(0xFFEA9A30)),
  _EmergencyOption('Flood / Water', Icons.flood_rounded, Color(0xFFDDF3FF), Color(0xFF39A6D8)),
  _EmergencyOption('Rescue', Icons.safety_check_rounded, Color(0xFFEDE3FF), Color(0xFF9873DB)),
  _EmergencyOption('Evacuation', Icons.exit_to_app_rounded, Color(0xFFFFF4BF), Color(0xFFD7A900)),
  _EmergencyOption('Missing Person', Icons.person_search_rounded, Color(0xFFD8F8F1), Color(0xFF32AFA0)),
  _EmergencyOption('Shelter', Icons.cabin_rounded, Color(0xFFFFE4EC), Color(0xFFE95B7E)),
  _EmergencyOption('Food & Water', Icons.water_drop_rounded, Color(0xFFDDF8F8), Color(0xFF32AFA0)),
  _EmergencyOption('Blood Needed', Icons.bloodtype_rounded, Color(0xFFFFE4EC), Color(0xFFE43B52)),
  _EmergencyOption('Drug Abuse', Icons.health_and_safety_rounded, Color(0xFFFFE5EE), Color(0xFFE95B7E)),
  _EmergencyOption('Other Emergency', Icons.more_horiz_rounded, Color(0xFFE8E9FF), Color(0xFF777DD1)),
];
const _women = <_EmergencyOption>[
  _EmergencyOption('Immediate Danger', Icons.sos_rounded, Color(0xFFFFE1EB), Color(0xFFE95B88)),
  _EmergencyOption('Harassment / Threat', Icons.shield_rounded, Color(0xFFEDE4FF), Color(0xFF9873DB)),
  _EmergencyOption('Unsafe Situation', Icons.visibility_rounded, Color(0xFFFFEFD4), Color(0xFFEA9A30)),
  _EmergencyOption('Escort Assistance', Icons.diversity_3_rounded, Color(0xFFD8FBF2), Color(0xFF32B7A6)),
  _EmergencyOption('Medical Emergency', Icons.medical_services_rounded, Color(0xFFDDF3FF), Color(0xFF39A6D8)),
  _EmergencyOption('Safe Shelter', Icons.home_work_rounded, Color(0xFFFFF4BF), Color(0xFFD7A900)),
  _EmergencyOption('Blood Needed', Icons.bloodtype_rounded, Color(0xFFEDE4FF), Color(0xFF9873DB)),
  _EmergencyOption('Other Women’s Emergency', Icons.more_horiz_rounded, Color(0xFFDDF8F8), Color(0xFF32AFA0)),
];
const _children = <_EmergencyOption>[
  _EmergencyOption('Lost / Missing Child', Icons.person_pin_circle_rounded, Color(0xFFFFE4EC), Color(0xFFE95B7E)),
  _EmergencyOption('Abuse / Unsafe Touch', Icons.pan_tool_rounded, Color(0xFFDDF8E4), Color(0xFF55B875)),
  _EmergencyOption('Stranger Danger', Icons.warning_rounded, Color(0xFFFFEFD4), Color(0xFFEA9A30)),
  _EmergencyOption('Bullying', Icons.sentiment_dissatisfied_rounded, Color(0xFFEDE3FF), Color(0xFF9873DB)),
  _EmergencyOption('Medical Emergency', Icons.medical_services_rounded, Color(0xFFDDF3FF), Color(0xFF39A6D8)),
  _EmergencyOption('Safe Pickup / Trusted Adult', Icons.verified_user_rounded, Color(0xFFFFF4BF), Color(0xFFD7A900)),
  _EmergencyOption('Child in Danger', Icons.shield_rounded, Color(0xFFFFE1EB), Color(0xFFE95B88)),
  _EmergencyOption('Other Child Emergency', Icons.more_horiz_rounded, Color(0xFFE4EEFF), Color(0xFF7195D7)),
];

class SosSelectionScreen extends StatefulWidget {
  const SosSelectionScreen({super.key});
  @override
  State<SosSelectionScreen> createState() => _SosSelectionScreenState();
}

class _SosSelectionScreenState extends State<SosSelectionScreen> {
  int _kind = 0;
  String get _title => const ['Choose Your SOS', 'General SOS', 'Women SOS', 'Child SOS'][_kind];
  List<_EmergencyOption> get _options => _kind == 1 ? _general : _kind == 2 ? _women : _children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _page, foregroundColor: _navy, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 30), onPressed: () => _kind == 0 ? Navigator.pop(context) : setState(() => _kind = 0)),
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.w900, color: _navy, fontSize: 24)),
      ),
      body: _kind == 0 ? _chooseKind() : _categoryGrid(),
    );
  }

  Widget _chooseKind() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
    children: [
      const Text('Select the help you need', textAlign: TextAlign.center, style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 24),
      _kindCard('GENERAL SOS', 'Emergency help for everyone', Icons.health_and_safety_rounded, const Color(0xFF219ED8), Colors.white, 1),
      const SizedBox(height: 18),
      _kindCard('WOMEN SOS', 'Safety, protection and support', Icons.shield_rounded, const Color(0xFFE82D87), Colors.white, 2),
      const SizedBox(height: 18),
      _kindCard('CHILD SOS', 'Protecting children, every moment', Icons.child_care_rounded, const Color(0xFFFFD528), _navy, 3),
      const SizedBox(height: 18),
      const Text('If someone is in immediate danger in India, call 112. Do not wait for an app response.', textAlign: TextAlign.center, style: TextStyle(color: _navy, fontSize: 13, height: 1.45)),
    ],
  );

  Widget _kindCard(String title, String subtitle, IconData icon, Color color, Color foreground, int kind) => Material(
    color: color, borderRadius: BorderRadius.circular(26), elevation: 3,
    child: InkWell(borderRadius: BorderRadius.circular(26), onTap: () => setState(() => _kind = kind), child: Padding(
      padding: const EdgeInsets.all(20), child: Row(children: [
        Container(width: 76, height: 76, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .8), borderRadius: BorderRadius.circular(20)), child: Icon(icon, size: 48, color: kind == 2 ? color : _navy)),
        const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: foreground, fontWeight: FontWeight.w900, fontSize: 21)), const SizedBox(height: 8), Text(subtitle, style: TextStyle(color: foreground, fontSize: 15)), const SizedBox(height: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .8), borderRadius: BorderRadius.circular(30)), child: Text('TAP TO CONTINUE  →', style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 12)))])), Icon(Icons.chevron_right_rounded, color: foreground, size: 34),
      ]),
    )),
  );

  Widget _categoryGrid() => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth >= 600 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _options.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: constraints.maxWidth < 380 ? 1.12 : 1.22),
      itemBuilder: (context, index) {
        final item = _options[index];
        return Material(color: item.background, borderRadius: BorderRadius.circular(22), child: InkWell(
          borderRadius: BorderRadius.circular(22), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => VictimScreen(initialCategory: item.title))),
          child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Row(children: [Expanded(child: Icon(item.icon, color: item.accent, size: 54)), Icon(Icons.arrow_forward_rounded, color: _navy.withValues(alpha: .85), size: 24)])),
            const SizedBox(height: 8), Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navy, fontSize: 16, fontWeight: FontWeight.w900, height: 1.15)),
          ])),
        ));
      },
    );
  });
}
