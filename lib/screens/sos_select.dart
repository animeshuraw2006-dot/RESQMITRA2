import 'package:flutter/material.dart';
import '../ui_meta.dart';
import '../widgets.dart';
import 'blood_request.dart';
import 'confirm_emergency.dart';

const kNavy = Color(0xFF0A1A4F);
const kTitleBlue = Color(0xFF0B3C6E);

BoxDecoration softBackground() => const BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8F5FD), Color(0xFFF3F8FE)]));

double _scale(BuildContext c) => (MediaQuery.of(c).size.width / 411).clamp(.8, 1.25);

// ───────────────────────── CHOOSE YOUR SOS ─────────────────────────
class ChooseSosScreen extends StatelessWidget {
  const ChooseSosScreen({super.key});

  Widget _card(BuildContext c, double s, int i,
      {required String title,
      required String sub,
      required String tile,
      required List<Color> grad,
      required Color text,
      required Color pill,
      required Color pillText,
      required Widget next}) {
    return FadeSlide(
      delayMs: 120 * i,
      child: Pressable(
        onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => next)),
        child: Container(
          margin: EdgeInsets.only(bottom: 18 * s),
          height: 134 * s,
          padding: EdgeInsets.symmetric(horizontal: 14 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24 * s),
            gradient: LinearGradient(colors: grad, begin: Alignment.centerLeft, end: Alignment.centerRight),
            boxShadow: [BoxShadow(color: grad.first.withOpacity(.35), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(20 * s),
                child: Image.asset(tile, width: 82 * s, height: 82 * s, fit: BoxFit.cover)),
            SizedBox(width: 12 * s),
            Container(width: 1.4, height: 86 * s, color: text.withOpacity(.55)),
            SizedBox(width: 14 * s),
            Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 23 * s, fontWeight: FontWeight.w900, color: text, height: 1.1)),
              SizedBox(height: 2 * s),
              Text(sub, style: TextStyle(fontSize: 14.5 * s, color: text)),
              SizedBox(height: 9 * s),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 7 * s),
                decoration: BoxDecoration(color: pill, borderRadius: BorderRadius.circular(22 * s)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('TAP TO CONTINUE', style: TextStyle(fontSize: 11.5 * s, fontWeight: FontWeight.w900, color: pillText)),
                  SizedBox(width: 6 * s),
                  Icon(Icons.arrow_forward, size: 14 * s, color: pillText),
                ]),
              ),
            ])),
            Icon(Icons.chevron_right, color: text, size: 34 * s),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);
    return Scaffold(
      body: Container(
        decoration: softBackground(),
        child: SafeArea(
          child: ListView(padding: EdgeInsets.fromLTRB(16 * s, 6 * s, 16 * s, 20), children: [
            Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: kTitleBlue, size: 30), onPressed: () => Navigator.pop(context)),
              Expanded(
                  child: Text('CHOOSE YOUR SOS',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 27 * s, fontWeight: FontWeight.w900, color: kTitleBlue))),
              const SizedBox(width: 48),
            ]),
            SizedBox(height: 4 * s),
            Center(child: Text('Select the help you need', style: TextStyle(fontSize: 18 * s, fontWeight: FontWeight.w500, color: const Color(0xFF1C3F5C)))),
            SizedBox(height: 22 * s),
            _card(context, s, 0,
                title: 'GENERAL SOS', sub: 'Emergency help for everyone', tile: 'assets/ui/t_general.png',
                grad: const [Color(0xFF1C97DC), Color(0xFF2BA3E3)], text: Colors.white,
                pill: const Color(0xFFC7E8FB), pillText: kTitleBlue, next: const SosCategoryScreen(kind: 'General')),
            _card(context, s, 1,
                title: 'WOMEN SOS', sub: 'Safety, protection and support', tile: 'assets/ui/t_women.png',
                grad: const [Color(0xFFE21F7D), Color(0xFFE8408D)], text: Colors.white,
                pill: const Color(0xFFFCD1E5), pillText: const Color(0xFFD0206E), next: const SosCategoryScreen(kind: 'Women')),
            _card(context, s, 2,
                title: 'CHILD SOS', sub: 'Protecting children, every moment', tile: 'assets/ui/t_child.png',
                grad: const [Color(0xFFF7C419), Color(0xFFF7CE28)], text: const Color(0xFF0B4A6B),
                pill: const Color(0xFFFFEFBB), pillText: kTitleBlue, next: const SosCategoryScreen(kind: 'Child')),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Option lists ─────────────────────────
class SosOpt {
  final String label, key;
  const SosOpt(this.label, this.key);
}

const kSosOptions = <String, List<SosOpt>>{
  'General': [
    SosOpt('Medical Emergency', 'g_medical'), SosOpt('Accident', 'g_accident'),
    SosOpt('Fire', 'g_fire'), SosOpt('Flood / Water', 'g_flood'),
    SosOpt('Rescue', 'g_rescue'), SosOpt('Evacuation', 'g_evacuation'),
    SosOpt('Missing Person', 'g_missing'), SosOpt('Shelter', 'g_shelter'),
    SosOpt('Food & Water', 'g_food'), SosOpt('Blood Needed', 'g_blood'),
    SosOpt('Drug Abuse', 'g_drug'), SosOpt('Other Emergency', 'g_other'),
  ],
  'Women': [
    SosOpt('Immediate Danger', 'w_danger'), SosOpt('Harassment / Threat', 'w_harass'),
    SosOpt('Unsafe Situation', 'w_unsafe'), SosOpt('Escort Assistance', 'w_escort'),
    SosOpt('Medical Emergency', 'w_medical'), SosOpt('Safe Shelter', 'w_shelter'),
    SosOpt('Blood Needed', 'w_blood'), SosOpt("Other Women’s Emergency", 'w_other'),
  ],
  'Child': [
    SosOpt('Lost / Missing Child', 'c_lost'), SosOpt('Abuse / Unsafe Touch', 'c_abuse'),
    SosOpt('Stranger Danger', 'c_stranger'), SosOpt('Bullying', 'c_bully'),
    SosOpt('Medical Emergency', 'c_medical'), SosOpt('Safe Pickup / Trusted Adult', 'c_pickup'),
    SosOpt('Child in Danger', 'c_danger'), SosOpt('Other Child Emergency', 'c_other'),
  ],
};

// card width : height  (measured from the design screenshots)
const _aspect = {'General': 2.3, 'Women': 1.69, 'Child': 1.63};

class SosCategoryScreen extends StatelessWidget {
  final String kind; // General | Women | Child
  const SosCategoryScreen({super.key, required this.kind});

  void _open(BuildContext c, SosOpt o) {
    final cat = '$kind SOS';
    final img = 'assets/ui/${o.key}.png';
    if (o.label == 'Blood Needed') {
      Navigator.push(c, MaterialPageRoute(builder: (_) => BloodRequestScreen(category: cat, image: img)));
    } else {
      Navigator.push(
          c,
          MaterialPageRoute(
              builder: (_) => ConfirmEmergencyScreen(
                  category: cat, type: o.label, icon: Icons.emergency, color: Colors.red, image: img)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = kSosOptions[kind]!;
    final s = _scale(context);
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: softBackground(),
        child: SafeArea(
          child: Stack(children: [
            if (kind == 'Women')
              Positioned(top: 0, right: 0, child: Image.asset('assets/ui/w_heart.png', width: width * .38)),
            Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: kNavy, size: 30), onPressed: () => Navigator.pop(context)),
                  SizedBox(width: 6 * s),
                  Text('$kind SOS', style: TextStyle(fontSize: 31 * s, fontWeight: FontWeight.w900, color: kNavy)),
                  if (kind == 'Child')
                    Padding(padding: const EdgeInsets.only(left: 10), child: Image.asset('assets/ui/c_shield.png', height: 38 * s)),
                ]),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 11, crossAxisSpacing: 10, childAspectRatio: _aspect[kind]!),
                  itemCount: items.length,
                  itemBuilder: (_, i) => FadeSlide(
                    delayMs: 55 * i,
                    child: Pressable(onTap: () => _open(context, items[i]), child: _OptionCard(items[i])),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final SosOpt o;
  const _OptionCard(this.o);
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, b) {
        final w = b.maxWidth, h = b.maxHeight;
        final bg = Color(UiMeta.bg[o.key] ?? 0xFFEFF5FD);
        final arrow = Color(UiMeta.arrow[o.key] ?? 0xFFDDE8F8);
        final d = w * .135;
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(w * .05),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Stack(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.only(left: w * .012, top: h * .03),
                  child: Image.asset('assets/ui/${o.key}.png', height: h * .94, fit: BoxFit.fitHeight)),
              Expanded(
                  child: Padding(
                      padding: EdgeInsets.only(top: h * .2, right: w * .03, left: w * .005),
                      child: Text(o.label,
                          style: TextStyle(
                              fontSize: (w * .068).clamp(10.5, 16.0).toDouble(),
                              fontWeight: FontWeight.w900,
                              color: kNavy,
                              height: 1.2)))),
            ]),
            Positioned(
              right: w * .03,
              bottom: h * .09,
              child: Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(color: arrow, shape: BoxShape.circle),
                  child: Icon(Icons.arrow_forward, size: d * .52, color: kNavy)),
            ),
          ]),
        );
      });
}
