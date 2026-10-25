import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../badges.dart';
import '../services.dart';
import '../state.dart';

const _bg1 = Color(0xFF040A1C);
const _bg2 = Color(0xFF0C1740);
const _panel = Color(0xFF0C1839);
const _line = Color(0xFF1D2D5C);
const _gold = Color(0xFFFFC53D);

/// Shown ONLY after the help seeker taps "I AM SAFE" and chooses to appreciate
/// the rescuer. Badge + thank-you + rating + feedback → the responder's profile.
class AppreciateScreen extends StatefulWidget {
  final Sos? sos;
  const AppreciateScreen({super.key, this.sos});
  @override
  State<AppreciateScreen> createState() => _AppreciateScreenState();
}

class _AppreciateScreenState extends State<AppreciateScreen> {
  final _thanks = TextEditingController();
  final _feedback = TextEditingController();
  BadgeDef? _badge;
  int _rating = 0;

  @override
  void dispose() {
    _thanks.dispose();
    _feedback.dispose();
    super.dispose();
  }

  bool get _canSend => _badge != null || _rating > 0 || _thanks.text.trim().isNotEmpty || _feedback.text.trim().isNotEmpty;

  void _submit() {
    final a = Appreciation(
      sosId: widget.sos?.id ?? '',
      from: AppState.I.name,
      badgeKey: _badge?.key ?? '',
      message: _thanks.text.trim(),
      feedback: _feedback.text.trim(),
      rating: _rating,
    );
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color(0xFF1B9E4B), content: Text('Thank you! Your appreciation is on its way to your responder.')));
    Navigator.of(context).popUntil((r) => r.isFirst);
    // deliver once the home screen is visible (the responder's phone shows the badge reveal)
    Future.delayed(const Duration(milliseconds: 800), () => AlertService.I.sendAppreciation(a));
  }

  Widget _section(int n, String title, String sub, Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFD66B), Color(0xFFE79A00)])),
              child: Text('$n', style: const TextStyle(color: Color(0xFF3A2500), fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
              Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
            ])),
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF111F47),
        counterStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _gold, width: 1.6)),
      );

  Widget _badgeTile(BadgeDef b) {
    final sel = _badge?.key == b.key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _badge = sel ? null : b);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: sel ? b.color.withOpacity(.14) : const Color(0xFF0A1431),
          border: Border.all(color: sel ? b.color : _line, width: sel ? 2 : 1),
          boxShadow: sel ? [BoxShadow(color: b.color.withOpacity(.55), blurRadius: 18)] : null,
        ),
        child: Stack(children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(child: AnimatedScale(scale: sel ? 1.08 : 1, duration: const Duration(milliseconds: 220), child: Image.asset(b.asset, fit: BoxFit.contain))),
            const SizedBox(height: 6),
            Text(b.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: sel ? Colors.white : Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.15)),
          ]),
          if (sel) Positioned(right: 0, top: 0, child: Icon(Icons.check_circle, color: b.color, size: 20)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final who = widget.sos?.responder ?? 'your responder';
    return Scaffold(
      backgroundColor: _bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_bg2, _bg1])),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.maybePop(context)),
                const Expanded(
                    child: Text('Appreciate Your Responder', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                // hero
                Container(
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(colors: [Color(0xFF1B2E7A), Color(0xFF0B1440)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: Border.all(color: _gold.withOpacity(.45)),
                    boxShadow: [BoxShadow(color: _gold.withOpacity(.16), blurRadius: 24)],
                  ),
                  child: Row(children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFFFFD66B), Color(0xFFE79A00)]),
                          boxShadow: [BoxShadow(color: _gold.withOpacity(.5), blurRadius: 18)]),
                      child: const Icon(Icons.favorite, color: Color(0xFF3A2500), size: 38),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Because heroes deserve appreciation too',
                          style: TextStyle(color: _gold, fontSize: 17, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Text('$who was there when help was needed. Send a badge and a few kind words – they go straight to their profile.',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35)),
                    ])),
                  ]),
                ),

                _section(
                  1,
                  'Give an appreciation badge',
                  _badge == null ? 'Pick the badge that fits best' : _badge!.blurb,
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: kBadges.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .86),
                    itemBuilder: (_, i) => _badgeTile(kBadges[i]),
                  ),
                ),

                _section(
                  2,
                  'Say thank you',
                  'A personal message of gratitude',
                  TextField(
                    controller: _thanks,
                    maxLines: 3,
                    maxLength: 300,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Thank you for coming to help me…'),
                  ),
                ),

                _section(
                  3,
                  'Rate & share feedback',
                  'Helps us keep the community safe',
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (var i = 1; i <= 5; i++)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _rating = i == _rating ? 0 : i);
                          },
                          child: AnimatedScale(
                            scale: i <= _rating ? 1.12 : 1,
                            duration: const Duration(milliseconds: 160),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: Icon(i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 44, color: i <= _rating ? _gold : Colors.white30)),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _feedback,
                      maxLines: 3,
                      maxLength: 300,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: _deco('Tell us about your experience (optional)'),
                    ),
                  ]),
                ),

                const SizedBox(height: 4),
                Opacity(
                  opacity: _canSend ? 1 : .45,
                  child: GestureDetector(
                    onTap: _canSend ? _submit : null,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(colors: [Color(0xFFFFD66B), Color(0xFFE79A00)]),
                        boxShadow: [BoxShadow(color: _gold.withOpacity(.4), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.send_rounded, color: Color(0xFF3A2500)),
                        SizedBox(width: 10),
                        Text('SEND APPRECIATION', style: TextStyle(color: Color(0xFF3A2500), fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Skip for now', style: TextStyle(color: Colors.white60))),
                const SizedBox(height: 6),
                const Center(child: Text('REAL HELP CREATES REAL HEROES', style: TextStyle(color: Colors.white30, fontSize: 11, letterSpacing: 2.5))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
