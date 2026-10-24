import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../services.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'sos_sent.dart';

class ConfirmEmergencyScreen extends StatefulWidget {
  final String category, type;
  final IconData icon;
  final Color color;
  final String? image; // option artwork
  final Map<String, String>? details; // e.g. blood request
  const ConfirmEmergencyScreen(
      {super.key, required this.category, required this.type, required this.icon, required this.color, this.image, this.details});
  @override
  State<ConfirmEmergencyScreen> createState() => _ConfirmEmergencyScreenState();
}

class _ConfirmEmergencyScreenState extends State<ConfirmEmergencyScreen> {
  final _desc = TextEditingController();
  final _rec = AudioRecorder();
  final _tags = <String>{};
  double? _lat, _lng;
  String _addr = '';
  String? _photo, _audio;
  bool _recording = false, _sms = true, _doNotCall = false, _sending = false;
  int _secs = 0;
  Timer? _timer;

  Map<String, IconData> get _tagList => widget.details != null
      ? const {'ICU patient': Icons.local_hospital, 'Critical': Icons.warning_amber_rounded}
      : const {
          'Injured': Icons.favorite,
          'Unconscious': Icons.person,
          'Accident': Icons.directions_car,
          'Need an ambulance': Icons.local_hospital,
        };

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rec.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final p = await LocationService.current();
    if (p == null || !mounted) return;
    setState(() {
      _lat = p.latitude;
      _lng = p.longitude;
    });
    final a = await LocationService.address(p.latitude, p.longitude);
    if (mounted) setState(() => _addr = a);
  }

  Future<void> _photoTap() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1280);
    if (x != null) setState(() => _photo = x.path);
  }

  Future<void> _recTap() async {
    if (_recording) {
      final p = await _rec.stop();
      _timer?.cancel();
      setState(() {
        _recording = false;
        _audio = p;
      });
      return;
    }
    if (!await _rec.hasPermission()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission needed')));
      return;
    }
    final d = await getTemporaryDirectory();
    await _rec.start(const RecordConfig(), path: '${d.path}/sos_${DateTime.now().millisecondsSinceEpoch}.m4a');
    _secs = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secs++);
      if (_secs >= 60) _recTap();
    });
    setState(() => _recording = true);
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    if (_recording) await _recTap();
    if (_lat == null) await _locate();
    final sos = Sos(
      id: 'sos${DateTime.now().millisecondsSinceEpoch}',
      userId: AppState.I.uid,
      category: widget.category,
      type: widget.type,
      name: AppState.I.name,
      phone: AppState.I.phone,
      lat: _lat ?? 0,
      lng: _lng ?? 0,
      address: _addr,
      desc: _desc.text.trim(),
      tags: _tags.toList(),
      doNotCall: _doNotCall,
      details: widget.details ?? const {},
      photo: _photo,
      audio: _audio,
    );
    AlertService.I.dispatch(sos);
    if (_sms) SmsService.toContacts(sos.smsText);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SosSentScreen(sos: sos)));
  }

  Widget _card(Widget child, {EdgeInsets? pad}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: pad ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6EAF5))),
        child: child,
      );

  Widget _tool(IconData icon, Color c, String t, String d, VoidCallback onTap, {Widget? trailing}) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6EAF5))),
            child: Row(children: [
              Icon(icon, size: 38, color: c),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: const TextStyle(fontWeight: FontWeight.w900, color: C.navy)),
                Text(d, style: const TextStyle(fontSize: 11, color: C.grey)),
              ])),
              if (trailing != null) trailing,
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFDFDFF),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: C.navy), onPressed: () => Navigator.pop(context)),
                const Text('Confirm Emergency', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0A0F3C))),
                const Spacer(),
                const Icon(Icons.crisis_alert, color: Colors.red, size: 42),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), children: [
                _card(Row(children: [
                  widget.image != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.asset(widget.image!, width: 76, height: 76, fit: BoxFit.cover))
                      : CircleAvatar(radius: 34, backgroundColor: widget.color.withOpacity(.15), child: Icon(widget.icon, size: 38, color: widget.color)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                        child: const Text('EMERGENCY', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                    const SizedBox(height: 4),
                    Text(widget.type, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.navy)),
                    const Text('Your location and emergency details will be sent to the configured RESQ-MITRA responder backend.',
                        style: TextStyle(fontSize: 12, color: C.grey)),
                  ])),
                ])),
                if (widget.details != null)
                  _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Blood request details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.navy)),
                    const SizedBox(height: 8),
                    for (final e in widget.details!.entries)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: '${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            TextSpan(text: e.value, style: const TextStyle(fontSize: 13)),
                          ]))),
                  ])),
                _card(Row(children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Your Location', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.navy)),
                    Text(_lat == null ? 'Detecting location…' : '${_lat!.toStringAsFixed(4)}° N, ${_lng!.toStringAsFixed(4)}° E',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (_addr.isNotEmpty) Text('(Near $_addr)', style: const TextStyle(fontSize: 12)),
                  ])),
                  _lat == null
                      ? TextButton(onPressed: _locate, child: const Text('Retry'))
                      : const OkChip('Location detected'),
                ])),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.chat, color: C.royal),
                    const SizedBox(width: 8),
                    const Text('Describe the situation', style: TextStyle(fontWeight: FontWeight.w900, color: C.navy)),
                    const Spacer(),
                    Text('${_desc.text.length}/200', style: const TextStyle(fontSize: 12, color: C.grey)),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _desc,
                    maxLength: 200,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    decoration: fieldDeco('E.g. Describe the situation, exact landmark, injuries or special instructions…').copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 8),
                  const Text('Quick Tags:', style: TextStyle(fontWeight: FontWeight.w800)),
                  Wrap(spacing: 8, children: [
                    for (final e in _tagList.entries)
                      FilterChip(
                        avatar: Icon(e.value, size: 16),
                        label: Text(e.key),
                        selected: _tags.contains(e.key),
                        onSelected: (s) => setState(() => s ? _tags.add(e.key) : _tags.remove(e.key)),
                      ),
                  ]),
                ])),
                Row(children: [
                  _tool(Icons.photo_camera, C.royal, 'Camera', _photo == null ? 'Capture and share photos or videos.' : 'Photo attached ✓', _photoTap,
                      trailing: const Icon(Icons.chevron_right)),
                  const SizedBox(width: 10),
                  _tool(Icons.sms, C.both, 'SMS', 'Send an emergency message to your trusted contacts.', () => setState(() => _sms = !_sms),
                      trailing: Icon(_sms ? Icons.check_circle : Icons.circle_outlined, color: _sms ? C.ok : C.grey)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _tool(Icons.mic, Colors.deepPurple, 'Voice Recording',
                      _recording ? 'Recording… tap to stop' : (_audio != null ? 'Voice note saved ✓' : 'Tap to record your message (optional).'), _recTap,
                      trailing: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircleAvatar(radius: 18, backgroundColor: Colors.red, child: Icon(_recording ? Icons.stop : Icons.mic, color: Colors.white, size: 18)),
                        Text('00:${_secs.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ])),
                  const SizedBox(width: 10),
                  _tool(Icons.phone_disabled, C.both, 'Do Not Call', '(Notify via message only)', () => setState(() => _doNotCall = !_doNotCall),
                      trailing: Switch(value: _doNotCall, onChanged: (v) => setState(() => _doNotCall = v))),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF5F5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFD6D6))),
                  child: const Row(children: [
                    Icon(Icons.shield, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(child: Text('You can cancel within 10 seconds if this is a mistake.', style: TextStyle(fontSize: 13))),
                    Icon(Icons.timer, color: Colors.red),
                    Text(' 10s', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(children: [
                PButton(_sending ? 'SENDING…' : 'CONFIRM & SEND SOS', color: Colors.red, radius: 30, height: 58,
                    icon: Icons.warning_rounded, onTap: _sending ? null : _send),
                const SizedBox(height: 4),
                const Text('Your emergency details are shared securely with the configured responder service.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: C.grey)),
                TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('Go back', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy))),
              ]),
            ),
          ]),
        ),
      );
}
