import 'package:flutter/material.dart';
import '../avatar.dart';
import '../badges.dart';
import '../services.dart';
import '../state.dart';
import '../theme.dart';
import '../verify_items.dart';
import 'complete_verification.dart';
import 'role_select.dart';

// ── dark "command centre" palette ──
const kPBg = Color(0xFF040A1A);
const kPCard = Color(0xFF0A1530);
const kPLine = Color(0xFF1A2A55);
const kTeal = Color(0xFF1ED6A4);
const kGold = Color(0xFFFFC53D);
const kIce = Color(0xFF8DB8FF);

Route<T> profileRoute<T>(String name, Widget page) =>
    MaterialPageRoute<T>(settings: RouteSettings(name: name), builder: (_) => page);

BoxDecoration _cardDeco() => BoxDecoration(
      color: kPCard,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: kPLine),
    );

// ───────────────────────── role switcher ─────────────────────────
Future<void> showRoleSheet(BuildContext c) async {
  final cur = AppState.I.role;
  final r = await showModalBottomSheet<String>(
    context: c,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RoleSheet(current: cur),
  );
  if (r == null || r == cur) return;
  await AppState.I.setRole(r);
  if (c.mounted) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(
        content: Text('Role changed to ${roleLabel(r)}.${r != 'seeker' ? ' Complete any pending items to start receiving alerts.' : ''}')));
  }
}

class _RoleSheet extends StatefulWidget {
  final String current;
  const _RoleSheet({required this.current});
  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends State<_RoleSheet> {
  late String _sel = widget.current;

  Widget _opt(String id, String title, String sub, IconData icon, Color color) {
    final on = _sel == id;
    return GestureDetector(
      onTap: () => setState(() => _sel = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: on ? color.withOpacity(.14) : const Color(0xFF0E1A3C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? color : kPLine, width: on ? 2 : 1),
        ),
        child: Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withOpacity(.18), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
            Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ])),
          Icon(on ? Icons.check_circle : Icons.circle_outlined, color: on ? color : Colors.white30),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        decoration: const BoxDecoration(
            color: Color(0xFF07112B), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            const Text('Switch role', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Choose how you want to use ResQMitra.', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 16),
            _opt('seeker', 'HELP SEEKER', 'Need assistance', Icons.shield_outlined, C.seeker),
            _opt('rescuer', 'RESCUER', 'Help others', Icons.person, C.rescuer),
            _opt('both', 'BOTH', 'Seek help and respond', Icons.groups, C.both),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context, _sel),
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [Color(0xFF2D8CFF), Color(0xFF1F3FD6)])),
                child: const Text('CONFIRM ROLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
            ),
          ]),
        ),
      );
}

// ───────────────────────── badge detail ─────────────────────────
void showBadgeDetail(BuildContext c, BadgeDef b, List<Map<String, dynamic>> got) {
  showModalBottomSheet(
    context: c,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      decoration: BoxDecoration(
        color: const Color(0xFF07112B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: b.color.withOpacity(.7), width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 14),
          Stack(alignment: Alignment.center, children: [
            Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [b.color.withOpacity(.45), b.color.withOpacity(0)]))),
            ColorFiltered(
                colorFilter: got.isEmpty ? kGreyFilter : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: Image.asset(b.asset, height: 150)),
          ]),
          Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(b.blurb, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14.5)),
          const SizedBox(height: 14),
          if (got.isEmpty)
            const Text('Not earned yet – keep helping and this badge can be yours.', textAlign: TextAlign.center, style: TextStyle(color: kGold))
          else ...[
            Text('Earned ${got.length} time${got.length == 1 ? '' : 's'}', style: TextStyle(color: b.color, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final g in got.reversed.take(3))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: kPLine)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('♥ from ${g['from'] ?? 'a help seeker'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  if ((g['message'] ?? '').toString().isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('“${g['message']}”', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic))),
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text(fmtDate((g['time'] ?? '').toString()), style: const TextStyle(color: Colors.white38, fontSize: 11.5))),
                ]),
              ),
          ],
        ]),
      ),
    ),
  );
}

// ───────────────────────── PROFILE SCREEN ─────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kPBg,
        body: AnimatedBuilder(
          animation: Listenable.merge([AppState.I, AppState.I.online]),
          builder: (c, _) => _body(c),
        ),
      );

  // ── pieces ──
  Widget _logo() => const Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Res', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        Icon(Icons.location_on, color: Color(0xFFFF3B4E), size: 24),
        Text('Mitra', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
      ]);

  Widget _header(BuildContext c, Map<String, dynamic> p) {
    final rescuer = AppState.I.isRescuer;
    final img = avatarProvider(p);
    final on = AppState.I.online.value;
    final loc = [p['pcity'], p['pstate']].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    final quote = (p['tagline'] ?? '').toString().isNotEmpty ? p['tagline'].toString() : (rescuer ? 'Ready to help. Always.' : 'Safety first. Always.');
    return Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _SkylinePainter())),
      SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 20),
          child: Column(children: [
            Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.maybePop(c)),
              _logo(),
              const Spacer(),
              IconButton(
                  icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle, border: Border.all(color: kPLine)),
                      child: const Icon(Icons.settings, color: Colors.white, size: 20)),
                  onPressed: () => Navigator.push(c, profileRoute('/profile/settings', const _SettingsScreen()))),
            ]),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kTeal, Color(0xFF2D8CFF)])),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF14224A),
                      backgroundImage: img,
                      child: img == null
                          ? Text(initialsOf(AppState.I.name), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900))
                          : null,
                    ),
                  ),
                  if (rescuer)
                    Positioned(
                        right: 4,
                        bottom: 6,
                        child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                                color: on ? const Color(0xFF22C55E) : Colors.grey, shape: BoxShape.circle, border: Border.all(color: kPBg, width: 3)))),
                ]),
                const SizedBox(width: 16),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppState.I.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.shield, color: kIce, size: 20),
                      const SizedBox(width: 6),
                      Flexible(child: Text(roleLabel(AppState.I.role), style: const TextStyle(color: kIce, fontSize: 16.5, fontWeight: FontWeight.w800))),
                    ]),
                    if (loc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 18),
                          const SizedBox(width: 5),
                          Expanded(child: Text(loc, style: const TextStyle(color: Colors.white70, fontSize: 14))),
                        ]),
                      ),
                    const SizedBox(height: 6),
                    Text('“$quote”', style: const TextStyle(color: kIce, fontSize: 14.5, fontStyle: FontStyle.italic)),
                  ]),
                )),
              ]),
            ),
            if (rescuer)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => AppState.I.setOnline(!on),
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                        color: Colors.black45, borderRadius: BorderRadius.circular(30), border: Border.all(color: on ? const Color(0xFF22C55E) : Colors.grey)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle, size: 11, color: on ? const Color(0xFF22C55E) : Colors.grey),
                      const SizedBox(width: 8),
                      Text(on ? 'Available' : 'Offline', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    ]);
  }

  Widget _stats() {
    final r = AppState.I.rating;
    Widget stat(IconData i, Color col, String v, String l) => Expanded(
            child: Column(children: [
          Icon(i, color: col, size: 28),
          const SizedBox(height: 6),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(l, textAlign: TextAlign.center, style: const TextStyle(color: kIce, fontSize: 12)),
        ]));
    Widget div() => Container(width: 1, height: 58, color: kPLine);
    final rescuer = AppState.I.isRescuer;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _cardDeco(),
      child: Row(children: [
        stat(Icons.volunteer_activism, const Color(0xFF4DA3FF), rescuer ? '${AppState.I.responded}' : '${AppState.I.sent}', rescuer ? 'SOS Responded' : 'SOS Sent'),
        div(),
        stat(Icons.star, kGold, r == null ? '—' : r.toStringAsFixed(1), 'Rating'),
        div(),
        stat(Icons.verified_user, const Color(0xFFB07CFF), '${AppState.I.earnedKeys.length}', 'Badges Earned'),
        div(),
        stat(Icons.calendar_month, kTeal, '${AppState.I.daysActive}', 'Days Active'),
      ]),
    );
  }

  Widget _roleCard(BuildContext c) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Row(children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: C.both.withOpacity(.16), shape: BoxShape.circle),
              child: Icon(AppState.I.role == 'seeker' ? Icons.shield_outlined : AppState.I.role == 'rescuer' ? Icons.person : Icons.groups, color: C.both, size: 28)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('SELECTED ROLE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
            const SizedBox(height: 2),
            Text(roleLabel(AppState.I.role), style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900)),
          ])),
          GestureDetector(
            onTap: () => showRoleSheet(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF2D8CFF), Color(0xFF1F3FD6)])),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text('SWITCH ROLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: .6)),
              ]),
            ),
          ),
        ]),
      );

  Widget _verification(BuildContext c) {
    final items = verificationItems();
    final pct = completionPercent(items);
    final pending = items.where((e) => !e.ok).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(pending.isEmpty ? Icons.verified : Icons.pending_actions, color: pending.isEmpty ? kTeal : kGold),
          const SizedBox(width: 10),
          const Expanded(child: Text('Profile Verification', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
          Text('$pct%', style: TextStyle(color: pending.isEmpty ? kTeal : kGold, fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: pct / 100, minHeight: 8, backgroundColor: kPLine, valueColor: AlwaysStoppedAnimation(pending.isEmpty ? kTeal : kGold)),
        ),
        const SizedBox(height: 8),
        for (final it in items)
          InkWell(
            onTap: it.ok ? null : () => Navigator.push(c, profileRoute('/profile/complete', CompleteVerificationScreen(focus: it.key))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: it.color.withOpacity(.14), shape: BoxShape.circle),
                    child: Icon(it.icon, color: it.color, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(it.label, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700))),
                Icon(it.ok ? Icons.check_circle : Icons.schedule, size: 17, color: it.color),
                const SizedBox(width: 5),
                Text(it.status, style: TextStyle(color: it.color, fontSize: 13, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        const SizedBox(height: 6),
        if (pending.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kGold.withOpacity(.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: kGold.withOpacity(.4))),
            child: Row(children: [
              const Icon(Icons.info_outline, color: kGold, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('${pending.length} item${pending.length == 1 ? '' : 's'} pending. You can still send an SOS meanwhile.', style: const TextStyle(color: Colors.white70, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(c, profileRoute('/profile/complete', const CompleteVerificationScreen())),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(colors: [Color(0xFF14C9A0), Color(0xFF0E8E8A)]),
                boxShadow: [BoxShadow(color: kTeal.withOpacity(.35), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.edit, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('COMPLETE PENDING VERIFICATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: .5)),
              ]),
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kTeal.withOpacity(.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: kTeal.withOpacity(.4))),
            child: const Row(children: [
              Icon(Icons.verified, color: kTeal, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Your profile is complete – thank you!', style: TextStyle(color: Colors.white70))),
            ]),
          ),
      ]),
    );
  }

  Widget _badges(BuildContext c) {
    final got = AppState.I.receivedBadges;
    final counts = <String, List<Map<String, dynamic>>>{};
    for (final g in got) {
      counts.putIfAbsent((g['badge'] ?? '').toString(), () => []).add(g);
    }
    final earned = kBadges.where((b) => counts.containsKey(b.key)).toList();
    final shown = earned.isNotEmpty ? earned : kBadges.take(5).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => Navigator.push(c, profileRoute('/profile/badges', const _BadgesScreen())),
          child: Row(children: [
            const Icon(Icons.emoji_events, color: kGold),
            const SizedBox(width: 10),
            const Expanded(child: Text('My Badges', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
            Text('${earned.length} / ${kBadges.length} Earned', style: const TextStyle(color: kIce, fontSize: 13.5)),
            const Icon(Icons.chevron_right, color: kIce),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 124,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final b in shown)
              GestureDetector(
                onTap: () => showBadgeDetail(c, b, counts[b.key] ?? const []),
                child: Container(
                  width: 92,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(children: [
                    SizedBox(
                      height: 82,
                      child: Stack(alignment: Alignment.center, children: [
                        ColorFiltered(
                            colorFilter: earned.isNotEmpty ? const ColorFilter.mode(Colors.transparent, BlendMode.dst) : kGreyFilter,
                            child: Opacity(opacity: earned.isNotEmpty ? 1 : .4, child: Image.asset(b.asset, height: 80))),
                        if (earned.isEmpty) const Icon(Icons.lock, color: Colors.white54, size: 22),
                        if ((counts[b.key]?.length ?? 0) > 1)
                          Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: b.color, borderRadius: BorderRadius.circular(10)),
                                  child: Text('×${counts[b.key]!.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)))),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text(b.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: earned.isNotEmpty ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.w700, height: 1.15)),
                  ]),
                ),
              ),
          ]),
        ),
        if (earned.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8, right: 8),
            child: Text('Badges appear here when people you help send you appreciation.', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
          ),
      ]),
    );
  }

  Widget _info(IconData i, Color col, String label, String value) => Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFF0F1D45), shape: BoxShape.circle), child: Icon(i, color: col, size: 20)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '—' : value, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
        ])),
      ]));

  Future<void> _editBio(BuildContext c, Map<String, dynamic> p) async {
    final bio = TextEditingController(text: (p['bio'] ?? '').toString());
    final quote = TextEditingController(text: (p['tagline'] ?? '').toString());
    final ok = await showDialog<bool>(
        context: c,
        builder: (_) => AlertDialog(
              title: const Text('Edit About Me'),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: quote, maxLength: 60, decoration: const InputDecoration(labelText: 'Tagline (e.g. Ready to help. Always.)')),
                  TextField(controller: bio, maxLines: 4, maxLength: 240, decoration: const InputDecoration(labelText: 'About me')),
                ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
              ],
            ));
    if (ok == true) await AppState.I.updateProfile({'bio': bio.text.trim(), 'tagline': quote.text.trim()});
  }

  Widget _about(BuildContext c, Map<String, dynamic> p) {
    final bio = (p['bio'] ?? '').toString().isNotEmpty
        ? p['bio'].toString()
        : (AppState.I.isRescuer
            ? 'I’m a volunteer responder. I believe in building a safer community and helping people in their toughest moments. Let’s make a difference together.'
            : 'I use ResQMitra to stay safe and connected to help whenever I need it.');
    final skills = p['skills'] is List ? (p['skills'] as List).join('  |  ') : '';
    final addr = [p['phouse'], p['pstreet'], p['pcity'], p['pdistrict'], p['ppin']].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.person, color: kIce),
          const SizedBox(width: 10),
          const Expanded(child: Text('About Me', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
          GestureDetector(
            onTap: () => _editBio(c, p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2D8CFF))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit, size: 16, color: Color(0xFF4DA3FF)),
                SizedBox(width: 6),
                Text('Edit', style: TextStyle(color: Color(0xFF4DA3FF), fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Text(bio, style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.45)),
        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(color: kPLine, height: 1)),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _info(Icons.phone, const Color(0xFF4DA3FF), 'Phone', AppState.I.phone.isEmpty ? '' : '+91 ${AppState.I.phone}'),
          const SizedBox(width: 10),
          _info(Icons.email, const Color(0xFF4DA3FF), 'Email', (p['email'] ?? '').toString()),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _info(Icons.water_drop, const Color(0xFFFF3B4E), 'Blood Group', (p['blood'] ?? '').toString()),
          const SizedBox(width: 10),
          _info(Icons.build_circle, const Color(0xFF4DA3FF), 'Skills', skills),
        ]),
        const SizedBox(height: 14),
        Row(children: [_info(Icons.home, kTeal, 'Address', addr)]),
        if ((p['allergies'] ?? '').toString().isNotEmpty || (p['conditions'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _info(Icons.medical_services, kGold, 'Allergies', (p['allergies'] ?? '').toString()),
            const SizedBox(width: 10),
            _info(Icons.monitor_heart, kGold, 'Conditions', (p['conditions'] ?? '').toString()),
          ]),
        ],
      ]),
    );
  }

  Widget _contacts() {
    final cs = AppState.I.contacts;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.contact_phone, color: kIce),
          SizedBox(width: 10),
          Text('Emergency Contacts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 10),
        if (cs.isEmpty) const Text('No emergency contacts yet.', style: TextStyle(color: Colors.white54)),
        for (final x in cs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              CircleAvatar(radius: 19, backgroundColor: const Color(0xFF0F1D45), child: Text(initialsOf((x['name'] ?? '').toString()), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((x['name'] ?? '').toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                Text('${x['relation'] ?? 'Contact'}  •  +91 ${x['phone']}', style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
              ])),
              IconButton(icon: const Icon(Icons.call, color: Color(0xFF22C55E)), onPressed: () => dial((x['phone'] ?? '').toString())),
            ]),
          ),
      ]),
    );
  }

  Widget _menu(BuildContext c) {
    Widget row(IconData i, Color col, String t, String? trail, VoidCallback onTap, {bool last = false}) => Column(children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(children: [
                Icon(i, color: col, size: 24),
                const SizedBox(width: 14),
                Expanded(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                if (trail != null) Text(trail, style: const TextStyle(color: Colors.white54)),
                const Icon(Icons.chevron_right, color: kIce),
              ]),
            ),
          ),
          if (!last) const Divider(color: kPLine, height: 1, indent: 16, endIndent: 16),
        ]);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: _cardDeco(),
      child: Column(children: [
        row(Icons.shield, const Color(0xFF4DA3FF), 'My SOS Responses', '${AppState.I.responded}', () => Navigator.push(c, profileRoute('/profile/responses', const _ResponsesScreen()))),
        row(Icons.star, kGold, 'My Ratings & Reviews', '${AppState.I.reviews.length}', () => Navigator.push(c, profileRoute('/profile/reviews', const _ReviewsScreen()))),
        row(Icons.settings, Colors.white70, 'Settings', null, () => Navigator.push(c, profileRoute('/profile/settings', const _SettingsScreen())), last: true),
      ]),
    );
  }

  Widget _body(BuildContext c) {
    final p = AppState.I.profile;
    return ListView(padding: EdgeInsets.zero, children: [
      _header(c, p),
      Transform.translate(offset: const Offset(0, -6), child: _stats()),
      _roleCard(c),
      _verification(c),
      _badges(c),
      _about(c, p),
      _contacts(),
      _menu(c),
      Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF07112B), borderRadius: BorderRadius.circular(18), border: Border.all(color: kPLine)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.shield, color: Color(0xFF4DA3FF), size: 22),
          SizedBox(width: 10),
          Text('Real People  |  Real Help  |  Safer Tomorrow', style: TextStyle(color: kIce, fontSize: 13)),
        ]),
      ),
    ]);
  }
}

class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B1A4A), Color(0xFF1A2F6B), Color(0xFF040A1A)])
              .createShader(Offset.zero & s));
    Path hill(double base, List<double> pts, double amp) {
      final p = Path()..moveTo(0, s.height);
      p.lineTo(0, s.height * base);
      for (var i = 0; i < pts.length; i++) {
        p.lineTo(s.width * (i + 1) / pts.length, s.height * (base - pts[i] * amp));
      }
      p.lineTo(s.width, s.height);
      p.close();
      return p;
    }

    canvas.drawPath(hill(.62, [.10, .22, .12, .30, .16, .26, .08, .18], .5), Paint()..color = const Color(0xFF16275A).withOpacity(.75));
    canvas.drawPath(hill(.78, [.06, .14, .22, .10, .18, .08, .16, .05], .5), Paint()..color = const Color(0xFF0C1840).withOpacity(.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ───────────────────────── sub screens ─────────────────────────
class _SubScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _SubScaffold(this.title, this.child);
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kPBg,
        appBar: AppBar(
          backgroundColor: kPBg,
          foregroundColor: Colors.white,
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        ),
        body: child,
      );
}

class _BadgesScreen extends StatelessWidget {
  const _BadgesScreen();
  @override
  Widget build(BuildContext context) => _SubScaffold(
        'My Badges',
        AnimatedBuilder(
          animation: AppState.I,
          builder: (c, _) {
            final got = AppState.I.receivedBadges;
            final by = <String, List<Map<String, dynamic>>>{};
            for (final g in got) {
              by.putIfAbsent((g['badge'] ?? '').toString(), () => []).add(g);
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text('${by.length} of ${kBadges.length} badges earned', style: const TextStyle(color: kIce, fontSize: 14.5)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kBadges.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .82),
                itemBuilder: (_, i) {
                  final b = kBadges[i];
                  final n = by[b.key]?.length ?? 0;
                  return GestureDetector(
                    onTap: () => showBadgeDetail(c, b, by[b.key] ?? const []),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                      decoration: BoxDecoration(
                        color: kPCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: n > 0 ? b.color.withOpacity(.8) : kPLine),
                        boxShadow: n > 0 ? [BoxShadow(color: b.color.withOpacity(.3), blurRadius: 14)] : null,
                      ),
                      child: Column(children: [
                        Expanded(
                          child: Stack(alignment: Alignment.center, children: [
                            ColorFiltered(
                                colorFilter: n > 0 ? const ColorFilter.mode(Colors.transparent, BlendMode.dst) : kGreyFilter,
                                child: Opacity(opacity: n > 0 ? 1 : .35, child: Image.asset(b.asset, fit: BoxFit.contain))),
                            if (n == 0) const Icon(Icons.lock, color: Colors.white54, size: 22),
                            if (n > 1)
                              Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: b.color, borderRadius: BorderRadius.circular(10)),
                                      child: Text('×$n', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)))),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        Text(b.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: n > 0 ? Colors.white : Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.15)),
                      ]),
                    ),
                  );
                },
              ),
            ]);
          },
        ),
      );
}

class _ResponsesScreen extends StatelessWidget {
  const _ResponsesScreen();
  @override
  Widget build(BuildContext context) {
    final l = AppState.I.responses.reversed.toList();
    return _SubScaffold(
      'My SOS Responses',
      l.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No completed responses yet.\nWhen you finish helping someone it will be listed here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, height: 1.4))))
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final r in l)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDeco(),
                  child: Row(children: [
                    const Icon(Icons.verified, color: kTeal, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${r['type']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      Text('${r['category']}  •  helped ${r['name']}', style: const TextStyle(color: kIce, fontSize: 13)),
                      if ((r['address'] ?? '').toString().isNotEmpty) Text('${r['address']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(fmtDate((r['time'] ?? '').toString()), style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
                    ])),
                  ]),
                ),
            ]),
    );
  }
}

class _ReviewsScreen extends StatelessWidget {
  const _ReviewsScreen();
  @override
  Widget build(BuildContext context) {
    final l = AppState.I.reviews.reversed.toList();
    final r = AppState.I.rating;
    return _SubScaffold(
      'Ratings & Reviews',
      l.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No reviews yet.\nHelp seekers can rate you after they are safe.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, height: 1.4))))
          : ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: _cardDeco(),
                child: Row(children: [
                  Text(r == null ? '—' : r.toStringAsFixed(1), style: const TextStyle(color: kGold, fontSize: 44, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [for (var i = 1; i <= 5; i++) Icon((r ?? 0) >= i - .25 ? Icons.star_rounded : Icons.star_outline_rounded, color: kGold, size: 26)]),
                    Text('${l.length} review${l.length == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white60)),
                  ])),
                ]),
              ),
              for (final x in l)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDeco(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('${x['from'] ?? 'Help seeker'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                      for (var i = 1; i <= 5; i++) Icon(i <= ((x['rating'] as num?)?.toInt() ?? 0) ? Icons.star : Icons.star_border, size: 16, color: kGold),
                    ]),
                    if ((x['text'] ?? '').toString().isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 6), child: Text('“${x['text']}”', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, height: 1.35))),
                    Padding(padding: const EdgeInsets.only(top: 6), child: Text(fmtDate((x['time'] ?? '').toString()), style: const TextStyle(color: Colors.white38, fontSize: 11.5))),
                  ]),
                ),
            ]),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();
  @override
  Widget build(BuildContext context) => _SubScaffold(
        'Settings',
        AnimatedBuilder(
          animation: Listenable.merge([AppState.I, AppState.I.online]),
          builder: (c, _) => ListView(padding: const EdgeInsets.all(16), children: [
            if (AppState.I.isRescuer)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: _cardDeco(),
                child: SwitchListTile(
                  activeColor: const Color(0xFF22C55E),
                  title: const Text('Available to respond', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  subtitle: const Text('Online responders get the siren pop-up for new SOS alerts', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
                  value: AppState.I.online.value,
                  onChanged: AppState.I.setOnline,
                ),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: _cardDeco(),
              child: ListTile(
                leading: const Icon(Icons.swap_horiz, color: kIce),
                title: const Text('Switch role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                subtitle: Text(roleLabel(AppState.I.role), style: const TextStyle(color: Colors.white54)),
                trailing: const Icon(Icons.chevron_right, color: kIce),
                onTap: () => showRoleSheet(c),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: _cardDeco(),
              child: ListTile(
                leading: const Icon(Icons.restart_alt, color: Color(0xFFFF5A6B)),
                title: const Text('Reset app data', style: TextStyle(color: Color(0xFFFF5A6B), fontWeight: FontWeight.w800)),
                subtitle: const Text('Deletes your profile, badges and history from this phone', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
                onTap: () async {
                  final ok = await showDialog<bool>(
                      context: c,
                      builder: (_) => AlertDialog(
                            title: const Text('Reset everything?'),
                            content: const Text('Your profile, badges, reviews and history will be erased and you will register again.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
                            ],
                          ));
                  if (ok == true) {
                    final nav = Navigator.of(c);
                    await AppState.I.reset();
                    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RoleSelectScreen()), (r) => false);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            const Center(child: Text('ResQMitra v1.0.0', style: TextStyle(color: Colors.white30))),
          ]),
        ),
      );
}
