import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'theme.dart';

class PButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final double radius, height;
  const PButton(this.label,
      {super.key, this.onTap, this.color = C.royal, this.icon, this.radius = 14, this.height = 52});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))),
          onPressed: onTap,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

Widget _label(String l, bool req) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(TextSpan(
          text: l,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.navy),
          children: [if (req) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))])),
    );

InputDecoration fieldDeco(String hint, {Widget? suffix, Widget? prefix}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AA3B5), fontSize: 14),
      filled: true,
      fillColor: C.field,
      isDense: true,
      suffixIcon: suffix,
      prefixIcon: prefix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.royal)),
    );

class AppField extends StatelessWidget {
  final String label, hint;
  final TextEditingController? ctrl;
  final bool required, readOnly;
  final TextInputType? type;
  final int maxLines;
  final int? maxLength;
  final Widget? suffix, prefix;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  const AppField(
      {super.key,
      required this.label,
      this.ctrl,
      this.hint = '',
      this.required = false,
      this.readOnly = false,
      this.type,
      this.maxLines = 1,
      this.maxLength,
      this.suffix,
      this.prefix,
      this.onTap,
      this.onChanged,
      this.validator});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(label, required),
          TextFormField(
            controller: ctrl,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            keyboardType: type,
            maxLines: maxLines,
            maxLength: maxLength,
            decoration: fieldDeco(hint.isEmpty ? 'Enter ${label.toLowerCase()}' : hint,
                suffix: suffix, prefix: prefix)
                .copyWith(counterText: ''),
            validator: validator ??
                (required ? (s) => (s == null || s.trim().isEmpty) ? 'Required' : null : null),
          ),
        ]),
      );
}

class AppDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final bool required;
  final ValueChanged<String?> onChanged;
  const AppDropdown(
      {super.key,
      required this.label,
      required this.items,
      required this.value,
      required this.onChanged,
      this.required = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(label, required),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: fieldDeco('Select ${label.toLowerCase()}'),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
            validator: required ? (s) => s == null ? 'Required' : null : null,
          ),
        ]),
      );
}

class RadioRow extends StatelessWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final Color color;
  const RadioRow(
      {super.key,
      required this.options,
      required this.value,
      required this.onChanged,
      this.color = C.royal});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Wrap(spacing: 18, runSpacing: 8, children: [
          for (final o in options)
            InkWell(
              onTap: () => onChanged(o),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(value == o ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20, color: value == o ? color : C.grey),
                const SizedBox(width: 6),
                Text(o, style: const TextStyle(fontSize: 13)),
              ]),
            ),
        ]),
      );
}

class CheckTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const CheckTile(this.label, this.value, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(value ? Icons.check_box : Icons.check_box_outline_blank,
                size: 22, color: value ? C.royal : C.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          ]),
        ),
      );
}

class SectionCard extends StatelessWidget {
  final int n;
  final String title, sub;
  final List<Widget> children;
  const SectionCard(this.n, this.title, this.sub, this.children, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                radius: 13,
                backgroundColor: C.royal,
                child: Text('$n',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: C.navy)),
              Text(sub, style: const TextStyle(fontSize: 12, color: C.royal)),
            ])),
          ]),
          const SizedBox(height: 14),
          ...children,
        ]),
      );
}

class OkChip extends StatelessWidget {
  final String text;
  final bool ok;
  const OkChip(this.text, {super.key, this.ok = true});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: (ok ? C.ok : C.warn).withOpacity(.12), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ok ? Icons.check_circle : Icons.schedule, size: 18, color: ok ? C.ok : C.warn),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: ok ? C.ok : C.warn)),
        ]),
      );
}

class UploadBox extends StatelessWidget {
  final String label;
  final String? path;
  final Uint8List? bytes;
  final VoidCallback onTap;
  const UploadBox(this.label, this.path, this.onTap, {super.key, this.bytes});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 84,
            width: double.infinity,
            decoration: BoxDecoration(
                color: C.field,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: C.border)),
            child: bytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      bytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 84,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.check_circle, color: C.ok),
                      ),
                    ),
                  )
                : path != null
                    ? const Center(
                        child: Icon(Icons.check_circle, color: C.ok),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.upload_file, color: C.royal),
                        const SizedBox(height: 4),
                        Text(label, style: const TextStyle(fontSize: 12, color: C.grey)),
                        const Text('(JPG, PNG – Max 5MB)',
                            style: TextStyle(fontSize: 11, color: C.grey)),
                      ]),
          ),
        ),
      );
}

/// Small non-interactive OpenStreetMap preview with a red pin.
class MiniMap extends StatelessWidget {
  final double lat, lng, height;
  const MiniMap(this.lat, this.lng, {super.key, this.height = 130});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
            children: [
              TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.resqmitra.app'),
              MarkerLayer(markers: [
                Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
              ]),
            ],
          ),
        ),
      );
}

/// Rescue status tracker (SOS Received → Assistance Provided).
class StatusStepper extends StatelessWidget {
  final int stage;
  const StatusStepper(this.stage, {super.key});
  static const labels = ['SOS Received', 'Responder Assigned', 'On the Way', 'Arrived', 'Assistance Provided'];
  static const icons = [Icons.sos, Icons.groups, Icons.directions_car, Icons.location_on, Icons.check_circle];
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < 5; i++) ...[
          Expanded(
              child: Column(children: [
            CircleAvatar(
                radius: 16,
                backgroundColor: i <= stage ? (i == 0 ? Colors.red : C.ok) : const Color(0xFFDDE3F0),
                child: Icon(icons[i], size: 16, color: i <= stage ? Colors.white : C.grey)),
            const SizedBox(height: 4),
            Text(labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: i <= stage ? FontWeight.w700 : FontWeight.w400,
                    color: i <= stage ? C.ok : C.grey)),
          ])),
        ],
      ]);
}


// ───────────────────────── Motion helpers ─────────────────────────
/// Fades + slides its child in after [delayMs] (used for staggered lists).
class FadeSlide extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const FadeSlide({super.key, required this.child, this.delayMs = 0});
  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _c,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .10), end: Offset.zero)
              .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic)),
          child: widget.child,
        ),
      );
}

/// Tap target with a springy press-down scale.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Pressable({super.key, required this.child, this.onTap});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
            scale: _down ? .96 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: widget.child),
      );
}

/// Bright-red SOS button: heart-beat (lub-dub) pulse, expanding signal rings
/// and a breathing glow.
class PulsingSosButton extends StatefulWidget {
  final double size; // total box incl. rings
  final VoidCallback onTap;
  const PulsingSosButton({super.key, required this.size, required this.onTap});
  @override
  State<PulsingSosButton> createState() => _PulsingSosButtonState();
}

class _PulsingSosButtonState extends State<PulsingSosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _bump(double x, double c, double w) => math.exp(-math.pow((x - c) / w, 2).toDouble());
  // two quick beats ("lub-dub") then rest
  static double _beat(double t) => math.max(_bump(t, .10, .045), .75 * _bump(t, .27, .05));

  @override
  Widget build(BuildContext context) {
    final btn = widget.size * .70;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final b = _beat(_c.value);
            return Stack(alignment: Alignment.center, children: [
              CustomPaint(size: Size(widget.size, widget.size), painter: _SignalRings(_c.value, btn)),
              Transform.scale(
                scale: 1 + .075 * b,
                child: Container(
                  width: btn,
                  height: btn,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                        center: Alignment(-.35, -.45),
                        radius: 1.0,
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF2020), Color(0xFFFF0000)],
                        stops: [0, .5, 1]),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFF1A1A).withOpacity(.40 + .30 * b),
                          blurRadius: 28 + 34 * b,
                          spreadRadius: 3 + 11 * b),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: btn * .90,
                    height: btn * .90,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(.30), width: 3)),
                    alignment: Alignment.center,
                    child: Text('SOS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: btn * .30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            shadows: [Shadow(color: Colors.black.withOpacity(.25), blurRadius: 8, offset: const Offset(0, 3))])),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _SignalRings extends CustomPainter {
  final double t, base;
  _SignalRings(this.t, this.base);
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final r = base / 2 * (1.0 + .42 * p);
      final fade = (1 - p);
      c.drawCircle(ctr, r, Paint()..color = const Color(0xFFFF1A1A).withOpacity(.10 * fade));
      c.drawCircle(
          ctr,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = const Color(0xFFFF2A2A).withOpacity(.55 * fade));
    }
  }

  @override
  bool shouldRepaint(_SignalRings o) => o.t != t;
}
