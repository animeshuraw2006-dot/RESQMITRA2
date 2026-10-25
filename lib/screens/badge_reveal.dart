import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../badges.dart';
import 'profile.dart';

/// Glowing full-screen reveal: the badge spins in the centre, then SPLASHES
/// (shock-wave rings + particles) and settles with the thank-you message.
class BadgeRevealScreen extends StatefulWidget {
  final BadgeDef badge;
  final String from, message;
  final int rating;
  const BadgeRevealScreen({super.key, required this.badge, required this.from, this.message = '', this.rating = 0});
  @override
  State<BadgeRevealScreen> createState() => _BadgeRevealScreenState();
}

class _BadgeRevealScreenState extends State<BadgeRevealScreen> with TickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 6400))..forward();
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final List<_Particle> _parts;
  bool _boomed = false;

  late final Animation<double> _spin = CurvedAnimation(parent: _c, curve: const Interval(0.04, 0.50, curve: Curves.easeOutCubic));
  late final Animation<double> _scaleIn = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.20, curve: Curves.easeOutBack));
  late final Animation<double> _splash = CurvedAnimation(parent: _c, curve: const Interval(0.50, 0.84, curve: Curves.easeOutCubic));
  late final Animation<double> _text = CurvedAnimation(parent: _c, curve: const Interval(0.62, 0.82, curve: Curves.easeOut));
  late final Animation<double> _btn = CurvedAnimation(parent: _c, curve: const Interval(0.80, 0.96, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    final r = math.Random(7);
    _parts = List.generate(70, (i) {
      final cols = [widget.badge.color, const Color(0xFFFFC53D), Colors.white, widget.badge.color.withOpacity(.7)];
      return _Particle(
          angle: r.nextDouble() * math.pi * 2,
          speed: .35 + r.nextDouble() * .75,
          size: 2.5 + r.nextDouble() * 5.5,
          color: cols[r.nextInt(cols.length)],
          star: r.nextBool());
    });
    HapticFeedback.mediumImpact();
    _c.addListener(() {
      if (!_boomed && _c.value >= .5) {
        _boomed = true;
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _viewProfile() {
    final nav = Navigator.of(context);
    nav.pushReplacement(MaterialPageRoute(settings: const RouteSettings(name: '/profile'), builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.badge;
    final size = MediaQuery.of(context).size;
    final badgeSize = math.min(size.width * .66, 290.0);
    return Scaffold(
      backgroundColor: const Color(0xFF030713),
      body: AnimatedBuilder(
        animation: Listenable.merge([_c, _loop]),
        builder: (_, __) {
          final angle = _spin.value * math.pi * 2 * 4; // 4 full turns, decelerating
          final pop = _c.value >= .5 && _c.value < .66 ? 1 + .16 * math.sin((_c.value - .5) / .16 * math.pi) : 1.0;
          final scale = (.25 + .75 * _scaleIn.value) * pop;
          final flash = _c.value >= .5 && _c.value < .6 ? (1 - (_c.value - .5) / .1) * .55 : 0.0;
          return Stack(fit: StackFit.expand, children: [
            // glowing backdrop + rotating rays
            CustomPaint(painter: _GlowPainter(b.color, _loop.value, .6 + .4 * math.sin(_loop.value * math.pi * 8).abs())),
            // splash
            CustomPaint(painter: _SplashPainter(_splash.value, _parts, b.color)),
            // spinning badge
            Align(
              alignment: const Alignment(0, -.28),
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: badgeSize + 60,
                  height: badgeSize + 60,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: badgeSize * 1.05,
                      height: badgeSize * 1.05,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [b.color.withOpacity(.55), b.color.withOpacity(0)])),
                    ),
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0013)
                        ..rotateY(angle),
                      child: Image.asset(b.asset, width: badgeSize, height: badgeSize, fit: BoxFit.contain),
                    ),
                  ]),
                ),
              ),
            ),
            // text
            Align(
              alignment: const Alignment(0, .72),
              child: Opacity(
                opacity: _text.value,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - _text.value)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('NEW BADGE RECEIVED',
                          style: TextStyle(color: Color(0xFFFFC53D), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      const SizedBox(height: 8),
                      Text(b.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(b.blurb, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14.5, height: 1.35)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.07),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: b.color.withOpacity(.55))),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('♥  from ${widget.from}', style: TextStyle(color: b.color, fontWeight: FontWeight.w900, fontSize: 14)),
                          if (widget.rating > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                for (var i = 1; i <= 5; i++)
                                  Icon(i <= widget.rating ? Icons.star : Icons.star_border, size: 18, color: const Color(0xFFFFC53D)),
                              ]),
                            ),
                          if (widget.message.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('“${widget.message}”',
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, height: 1.3)),
                            ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            // buttons
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Opacity(
                  opacity: _btn.value,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                    child: Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white38),
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              onPressed: _btn.value < .6 ? null : () => Navigator.of(context).pop(),
                              child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w800)))),
                      const SizedBox(width: 12),
                      Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: b.color,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              onPressed: _btn.value < .6 ? null : _viewProfile,
                              icon: const Icon(Icons.person),
                              label: const Text('VIEW IN MY PROFILE', style: TextStyle(fontWeight: FontWeight.w900)))),
                    ]),
                  ),
                ),
              ),
            ),
            // white flash on splash
            if (flash > 0) IgnorePointer(child: Container(color: Colors.white.withOpacity(flash))),
          ]);
        },
      ),
    );
  }
}

class _Particle {
  final double angle, speed, size;
  final Color color;
  final bool star;
  _Particle({required this.angle, required this.speed, required this.size, required this.color, required this.star});
}

class _GlowPainter extends CustomPainter {
  final Color color;
  final double t, pulse;
  _GlowPainter(this.color, this.t, this.pulse);
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height * .36);
    canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = RadialGradient(
                  colors: [color.withOpacity(.50 * pulse), const Color(0xFF0A1236).withOpacity(.92), const Color(0xFF030713)],
                  stops: const [0, .55, 1])
              .createShader(Rect.fromCircle(center: c, radius: s.height * .75)));
    // rotating light rays
    final ray = Paint()..color = color.withOpacity(.10);
    const n = 14;
    for (var i = 0; i < n; i++) {
      final a = t * math.pi * 2 + i * (math.pi * 2 / n);
      final p = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - .09) * s.height, c.dy + math.sin(a - .09) * s.height)
        ..lineTo(c.dx + math.cos(a + .09) * s.height, c.dy + math.sin(a + .09) * s.height)
        ..close();
      canvas.drawPath(p, ray);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter o) => o.t != t || o.pulse != pulse;
}

class _SplashPainter extends CustomPainter {
  final double t; // 0..1
  final List<_Particle> parts;
  final Color color;
  _SplashPainter(this.t, this.parts, this.color);

  void _star(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rr = i.isEven ? r : r * .4;
      final a = i * math.pi / 4;
      final pt = Offset(o.dx + math.cos(a) * rr, o.dy + math.sin(a) * rr);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  void paint(Canvas canvas, Size s) {
    if (t <= 0 || t >= 1) return;
    final c = Offset(s.width / 2, s.height * .36);
    final maxR = s.width * .95;
    // shock-wave rings
    for (var i = 0; i < 3; i++) {
      final k = ((t - i * .12) / .88).clamp(0.0, 1.0);
      if (k <= 0) continue;
      canvas.drawCircle(
          c,
          maxR * Curves.easeOut.transform(k),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 * (1 - k) + 1
            ..color = (i == 1 ? Colors.white : color).withOpacity((1 - k) * .8));
    }
    // particles
    for (final p in parts) {
      final d = maxR * .8 * p.speed * Curves.easeOutCubic.transform(t);
      final o = Offset(c.dx + math.cos(p.angle) * d, c.dy + math.sin(p.angle) * d + 60 * t * t);
      final paint = Paint()..color = p.color.withOpacity((1 - t).clamp(0.0, 1.0));
      p.star ? _star(canvas, o, p.size * 1.6, paint) : canvas.drawCircle(o, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter o) => o.t != t;
}
