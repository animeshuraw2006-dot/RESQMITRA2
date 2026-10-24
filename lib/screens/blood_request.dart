import 'package:flutter/material.dart';
import '../services.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'confirm_emergency.dart';
import 'sos_select.dart';

/// Shown BEFORE the confirmation page when "Blood Needed" is chosen.
class BloodRequestScreen extends StatefulWidget {
  final String category, image;
  const BloodRequestScreen({super.key, required this.category, required this.image});
  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen> {
  final _form = GlobalKey<FormState>();
  bool? _icu;
  String? _group, _component, _when;
  String _locMode = 'Detect location';
  double? _lat, _lng;
  String _addr = '';
  bool _detecting = false;
  final _units = TextEditingController();
  final _hospital = TextEditingController();
  final _doctor = TextEditingController();
  final _manual = TextEditingController();
  final _bank = TextEditingController();
  late final _attendant = TextEditingController(text: AppState.I.phone);

  static const _groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'];
  static const _components = ['Red blood cells', 'Platelets', 'Plasma', 'As advised by the hospital'];
  static const _whens = ['Immediately', 'Within 1 hour', 'Within 2 hours'];

  @override
  void dispose() {
    for (final c in [_units, _hospital, _doctor, _manual, _bank, _attendant]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _detect() async {
    setState(() => _detecting = true);
    final p = await LocationService.current();
    if (p == null) {
      if (mounted) setState(() => _detecting = false);
      return _snack('Turn on location and allow the permission');
    }
    final a = await LocationService.address(p.latitude, p.longitude);
    if (mounted) setState(() {
      _lat = p.latitude;
      _lng = p.longitude;
      _addr = a;
      _detecting = false;
    });
  }

  Widget _heading(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(TextSpan(text: t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.navy),
          children: const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))])));

  Widget _yesNo(String label, bool value, Color color, IconData icon) {
    final sel = _icu == value;
    return Expanded(
      child: Pressable(
        onTap: () => setState(() => _icu = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: sel ? color : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? color : C.border, width: 2),
              boxShadow: sel ? [BoxShadow(color: color.withOpacity(.35), blurRadius: 14, offset: const Offset(0, 6))] : []),
          child: Column(children: [
            Icon(icon, size: 30, color: sel ? Colors.white : color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: sel ? Colors.white : C.navy)),
          ]),
        ),
      ),
    );
  }

  void _continue() {
    if (!_form.currentState!.validate()) return _snack('Please fill the highlighted fields');
    if (_component == null) return _snack('Select the blood component required');
    if (_when == null) return _snack('Select when the blood is required');
    if (_locMode == 'Detect location' && _lat == null) return _snack('Tap “Detect hospital location” or enter it manually');
    final loc = _locMode == 'Detect location'
        ? '${_addr.isEmpty ? "Detected" : _addr} (${LocationService.mapsLink(_lat!, _lng!)})'
        : _manual.text.trim();
    final details = <String, String>{
      'ICU emergency': 'Yes',
      'Blood group': _group!,
      'Component': _component!,
      'Units': _units.text.trim().isEmpty ? 'As prescribed by the treating team' : _units.text.trim(),
      'Hospital': _hospital.text.trim(),
      'Doctor': _doctor.text.trim(),
      'Hospital location': loc,
      if (_bank.text.trim().isNotEmpty) 'Blood bank contact': _bank.text.trim(),
      'Required by': _when!,
      'Attendant contact': _attendant.text.trim(),
    };
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ConfirmEmergencyScreen(
                category: widget.category, type: 'Blood Needed', icon: Icons.bloodtype, color: Colors.red,
                image: widget.image, details: details)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: softBackground(),
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: kNavy, size: 30), onPressed: () => Navigator.pop(context)),
                  const Text('Blood Needed', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kNavy)),
                ]),
              ),
              Expanded(
                child: Form(
                  key: _form,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 24), children: [
                    FadeSlide(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.border)),
                        child: Row(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(widget.image, width: 70, height: 70, fit: BoxFit.cover)),
                          const SizedBox(width: 14),
                          const Expanded(
                              child: Text('Is the Patient in ICU Emergency?',
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.navy))),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      _yesNo('YES', true, C.ok, Icons.check_circle_outline),
                      const SizedBox(width: 12),
                      _yesNo('NO', false, Colors.red, Icons.highlight_off),
                    ]),
                    const SizedBox(height: 16),
                    if (_icu == false)
                      FadeSlide(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(.5))),
                          child: Column(children: [
                            const Icon(Icons.info_rounded, color: Colors.red, size: 40),
                            const SizedBox(height: 8),
                            const Text('This Blood needed Emergency Option can only be used for ICU emergency situations',
                                textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.navy)),
                            const SizedBox(height: 14),
                            PButton('Go back', color: C.navy, onTap: () => Navigator.pop(context)),
                          ]),
                        ),
                      ),
                    if (_icu == true)
                      FadeSlide(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.border)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            AppDropdown(label: "Patient's Blood Group", items: _groups, value: _group, required: true, onChanged: (v) => setState(() => _group = v)),
                            _heading('Blood Component Required'),
                            RadioRow(options: _components, value: _component, onChanged: (v) => setState(() => _component = v)),
                            AppField(label: 'Units Required', ctrl: _units, hint: 'As prescribed by the treating team'),
                            AppField(label: 'Hospital Name', ctrl: _hospital, required: true, hint: 'Enter hospital name'),
                            AppField(label: "Doctor's name", ctrl: _doctor, required: true, hint: 'Enter doctor’s name'),
                            _heading('Hospital Location'),
                            RadioRow(options: const ['Detect location', 'Enter manually'], value: _locMode, onChanged: (v) => setState(() => _locMode = v)),
                            if (_locMode == 'Detect location') ...[
                              PButton(_detecting ? 'Detecting…' : 'Detect hospital location', icon: Icons.my_location, onTap: _detecting ? null : _detect),
                              const SizedBox(height: 8),
                              if (_lat != null) ...[
                                Text(_addr.isEmpty ? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}' : _addr, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 6),
                                const OkChip('Location detected'),
                              ],
                              const SizedBox(height: 6),
                            ] else
                              AppField(label: 'Hospital address', ctrl: _manual, required: true, hint: 'Enter hospital address / landmark', maxLines: 2),
                            AppField(label: 'Hospital Blood Bank Contact', ctrl: _bank, type: TextInputType.phone, maxLength: 10, hint: 'Enter number, if known'),
                            _heading('Required By'),
                            RadioRow(options: _whens, value: _when, onChanged: (v) => setState(() => _when = v)),
                            AppField(
                                label: "Attendant's Contact Number",
                                ctrl: _attendant,
                                required: true,
                                type: TextInputType.phone,
                                maxLength: 10,
                                hint: 'Enter mobile number',
                                validator: (s) => (s == null || s.trim().length != 10) ? 'Enter a 10-digit mobile number' : null),
                            const SizedBox(height: 4),
                            PButton('CONTINUE', icon: Icons.arrow_forward, color: Colors.red, onTap: _continue),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
}
