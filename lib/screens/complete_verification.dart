import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../verify_items.dart';
import '../widgets.dart';
import 'registration.dart' show kStates, kSkills, kRelations;

/// Lets the user finish every PENDING item of the profile (or edit any item).
class CompleteVerificationScreen extends StatefulWidget {
  final String? focus; // item key to open first
  const CompleteVerificationScreen({super.key, this.focus});
  @override
  State<CompleteVerificationScreen> createState() => _CompleteVerificationScreenState();
}

class _CompleteVerificationScreenState extends State<CompleteVerificationScreen> {
  final _c = <String, TextEditingController>{};
  final _v = <String, dynamic>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _v.addAll(AppState.I.profile);
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _t(String k) => _c.putIfAbsent(k, () => TextEditingController(text: (_v[k] ?? '').toString()));
  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ── generic widgets ──
  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.navy)),
      );

  Widget _field(String k, String label, {TextInputType? type, int? max, int lines = 1, String? hint, ValueChanged<String>? onChanged}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl(label),
          TextField(
            controller: _t(k),
            keyboardType: type,
            maxLength: max,
            maxLines: lines,
            onChanged: onChanged,
            decoration: fieldDeco(hint ?? 'Enter ${label.toLowerCase()}').copyWith(counterText: ''),
          ),
        ]),
      );

  Widget _drop(String k, String label, List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl(label),
          DropdownButtonFormField<String>(
            value: items.contains(_v[k]) ? _v[k] as String : null,
            isExpanded: true,
            decoration: fieldDeco('Select ${label.toLowerCase()}'),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (x) => setState(() => _v[k] = x),
          ),
        ]),
      );

  Widget _status(bool ok, String t) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: (ok ? C.ok : C.warn).withOpacity(.12), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ok ? Icons.check_circle : Icons.schedule, size: 17, color: ok ? C.ok : C.warn),
          const SizedBox(width: 6),
          Text(t, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ok ? C.ok : C.warn)),
        ]),
      );

  Widget _smallBtn(String t, IconData i, VoidCallback onTap) => SizedBox(
        height: 46,
        child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: C.royal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: onTap,
            icon: Icon(i, size: 18),
            label: Text(t)),
      );

  // ── actions ──
  Future<String?> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Take a photo'), onTap: () => Navigator.pop(context, ImageSource.camera)),
              ListTile(leading: const Icon(Icons.photo_library), title: const Text('Upload from gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
            ])));
    if (src == null) return null;
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85);
      if (x == null) return null;
      try {
        // keep a permanent copy (picker files live in a cache that can be cleared)
        final dir = await getApplicationDocumentsDirectory();
        final f = await File(x.path).copy('${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg');
        return f.path;
      } catch (_) {
        return x.path;
      }
    } catch (_) {
      _snack('Unable to select this image. Please try again.');
      return null;
    }
  }

  Future<void> _pick(String k) async {
    final path = await _pickImage();
    if (path != null && mounted) setState(() => _v[k] = path);
  }

  Future<void> _verify(String flag, String target) async {
    if (flag != 'mobileV') return;
    final phone = target.replaceAll(RegExp(r'\D'), '');
    if (phone.length != 10) {
      _snack('Enter a valid 10-digit Indian mobile number');
      return;
    }
    if (_v['verifiedMobile'] != phone && mounted) {
      setState(() {
        _v['mobileV'] = false;
        _v.remove('verifiedMobile');
      });
    }
    final sent = await Api.I.sendPhoneOtp(phone);
    if (!mounted) return;
    if (!sent.ok) {
      _snack(sent.data['error']?.toString() ??
          'Could not send OTP. Check the backend and Renflair configuration.');
      return;
    }
    final code = TextEditingController();
    var verifying = false;
    String? errorText;
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refreshDialog) => AlertDialog(
          title: Text('Verify +91 $phone'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Enter the 6-digit verification code sent by SMS.'),
            const SizedBox(height: 8),
            TextField(controller: code, keyboardType: TextInputType.number,
              maxLength: 6, autofocus: true,
              decoration: const InputDecoration(labelText: 'SMS verification code')),
            if (errorText != null) ...[
              const SizedBox(height: 4),
              Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ]),
          actions: [
            TextButton(onPressed: verifying ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
            FilledButton(onPressed: verifying ? null : () async {
              final otp = code.text.trim();
              if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                refreshDialog(() => errorText = 'Enter the complete 6-digit OTP.');
                return;
              }
              refreshDialog(() { verifying = true; errorText = null; });
              final result = await Api.I.verifyPhoneOtp(phone, otp);
              if (!dialogContext.mounted) return;
              if (result.ok && result.data['verified'] == true) {
                Navigator.pop(dialogContext, true);
              } else {
                refreshDialog(() {
                  verifying = false;
                  errorText = result.data['error']?.toString() ??
                    (result.status == 0 ? 'Could not reach the server. Check internet and API_BASE.'
                      : 'OTP verification failed. Check the code and try again.');
                });
              }
            }, child: verifying
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Verify OTP')),
          ],
        ),
      ),
    );
    code.dispose();
    if (verified != true || !mounted) return;
    setState(() {
      _v['mobileV'] = true;
      _v['verifiedMobile'] = phone;
    });
    _snack('Phone number verified successfully');
  }

  Future<void> _gps() async {
    final p = await LocationService.current();
    if (p == null) return _snack('Turn on location and allow the permission');
    final a = await LocationService.address(p.latitude, p.longitude);
    if (!mounted) return;
    setState(() {
      _v['lat'] = p.latitude;
      _v['lng'] = p.longitude;
      _v['addr'] = a;
    });
  }

  Future<void> _save() async {
    final patch = <String, dynamic>{..._v};
    for (final e in _c.entries) {
      patch[e.key] = e.value.text.trim();
    }
    final mob = (patch['mobile'] ?? '').toString();
    if (mob.isNotEmpty && mob.length != 10) return _snack('Mobile number must be 10 digits');
    final normalizedMobile = mob.replaceAll(RegExp(r'\D'), '');
    if (normalizedMobile.isNotEmpty &&
        (_v['mobileV'] != true || _v['verifiedMobile'] != normalizedMobile)) {
      return _snack('Verify the current mobile number with SMS OTP before saving');
    }
    setState(() => _saving = true);
    await AppState.I.updateProfile(patch);
    if (!mounted) return;
    setState(() => _saving = false);
    _snack('Profile updated');
    Navigator.pop(context);
  }

  // ── editors ──
  Widget _photoBox(String k, {double h = 110}) {
    final path = (_v[k] ?? '').toString();
    return GestureDetector(
      onTap: () => _pick(k),
      child: Container(
        height: h,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: C.field, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
        child: path.isNotEmpty && File(path).existsSync()
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(path), fit: BoxFit.cover))
            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.cloud_upload_outlined, color: C.royal, size: 32),
                SizedBox(height: 4),
                Text('Tap to upload or take photo', style: TextStyle(color: C.grey, fontSize: 13)),
              ]),
      ),
    );
  }

  Widget _editor(String key) {
    switch (key) {
      case 'name':
        return _field('name', 'Full Name');
      case 'photo':
        return _photoBox('photo', h: 150);
      case 'mobile':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field('mobile', 'Mobile Number', type: TextInputType.phone, max: 10, hint: '98765 43210', onChanged: (_) => setState(() { _v['mobileV'] = false; _v.remove('verifiedMobile'); })),
          _status(_v['mobileV'] == true, _v['mobileV'] == true ? 'Mobile number verified' : 'Not verified yet'),
          if (_v['mobileV'] != true) _smallBtn('Send OTP', Icons.sms, () => _verify('mobileV', _t('mobile').text)),
        ]);
      case 'email':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field('email', 'Email Address', type: TextInputType.emailAddress, onChanged: (_) => setState(() {})),
          _status(_t('email').text.trim().isNotEmpty, _t('email').text.trim().isNotEmpty ? 'Email provided' : 'Optional / not provided'),
        ]);
      case 'address':
        return Column(children: [
          _field('phouse', 'House/Flat No.'),
          _field('pstreet', 'Street / Locality'),
          _field('pcity', 'Village / Town / City'),
          _field('pdistrict', 'District'),
          _drop('pstate', 'State/UT', kStates),
          _field('ppin', 'PIN Code', type: TextInputType.number, max: 6),
        ]);
      case 'gps':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PButton('Verify My Location', icon: Icons.my_location, onTap: _gps),
          const SizedBox(height: 10),
          if (_v['lat'] != null) ...[
            Text('Lat: ${(_v['lat'] as num).toStringAsFixed(4)}   Long: ${(_v['lng'] as num).toStringAsFixed(4)}', style: const TextStyle(fontSize: 12)),
            if ((_v['addr'] ?? '').toString().isNotEmpty) Text(_v['addr'].toString(), style: const TextStyle(fontSize: 12, color: C.grey)),
            const SizedBox(height: 8),
            MiniMap((_v['lat'] as num).toDouble(), (_v['lng'] as num).toDouble()),
            const SizedBox(height: 8),
            _status(true, 'Location verified'),
          ],
        ]);
      case 'contact1':
      case 'contact2':
        final i = key == 'contact1' ? 0 : 1;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field('c${i}name', 'Full Name'),
          _drop('c${i}rel', 'Relationship', kRelations),
          _field('c${i}phone', 'Mobile Number', type: TextInputType.phone, max: 10, hint: '98765 43210', onChanged: (_) => setState(() => _v['c${i}V'] = false)),
          _status(_v['c${i}V'] == true, _v['c${i}V'] == true ? 'Contact verified' : 'Not verified yet'),
          if (_v['c${i}V'] != true) _smallBtn('Send OTP', Icons.sms, () => _verify('c${i}V', _t('c${i}phone').text)),
        ]);
      case 'identity':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _drop('docType', 'Document Type', const ['Aadhaar Card', 'Voter ID', 'Driving Licence', 'Passport', 'PAN Card']),
          _photoBox('docPhoto'),
          _status(false, (_v['docPhoto'] ?? '').toString().isNotEmpty ? 'Verification status: Under review' : 'Not submitted'),
        ]);
      case 'medical':
        return Column(children: [
          _drop('blood', 'Blood Group', const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown']),
          _field('allergies', 'Allergies (Optional)', hint: 'e.g. penicillin, nuts'),
          _field('conditions', 'Medical Conditions (Optional)'),
          _field('meds', 'Current Medication (Optional)'),
        ]);
      case 'skills':
        final sel = (_v['skills'] is List) ? List<String>.from(_v['skills'] as List) : <String>[];
        return Wrap(spacing: 8, runSpacing: 4, children: [
          for (final s in kSkills)
            FilterChip(
              label: Text(s, style: TextStyle(fontSize: 12.5, color: sel.contains(s) ? Colors.white : C.navy)),
              selected: sel.contains(s),
              selectedColor: C.royal,
              checkmarkColor: Colors.white,
              onSelected: (on) => setState(() {
                final l = List<String>.from(sel);
                on ? l.add(s) : l.remove(s);
                _v['skills'] = l;
              }),
            ),
        ]);
    }
    return const SizedBox.shrink();
  }

  // live status (reflects what is typed in this session, not only what was saved)
  bool _liveOk(String key) {
    bool has(String k) => (_c[k] != null ? _c[k]!.text : (_v[k] ?? '').toString()).trim().isNotEmpty;
    switch (key) {
      case 'name':
        return has('name');
      case 'photo':
        return has('photo');
      case 'mobile':
        return _v['mobileV'] == true && _v['verifiedMobile'] == _t('mobile').text.replaceAll(RegExp(r'\D'), '');
      case 'email':
        return has('email');
      case 'address':
        return has('phouse');
      case 'gps':
        return _v['lat'] != null;
      case 'contact1':
        return has('c0phone');
      case 'contact2':
        return has('c1phone');
      case 'identity':
        return has('docPhoto');
      case 'medical':
        return has('blood') || has('allergies') || has('conditions');
      case 'skills':
        return _v['skills'] is List && (_v['skills'] as List).isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final items = verificationItems();
    final pending = items.where((e) => !_liveOk(e.key)).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(title: const Text('Complete Verification')),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 20), children: [
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: const Color(0xFFE4F3F2), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(pending == 0 ? Icons.verified : Icons.pending_actions, color: pending == 0 ? C.ok : C.warn),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(pending == 0 ? 'Everything is filled in – tap Save.' : '$pending item${pending == 1 ? '' : 's'} still pending. Open an item, fill it in and Save.',
                        style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            ),
            for (final it in items)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: widget.focus != null ? it.key == widget.focus : !_liveOk(it.key) && it.key == items.firstWhere((e) => !_liveOk(e.key), orElse: () => it).key,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    leading: CircleAvatar(radius: 19, backgroundColor: const Color(0xFFE1ECFD), child: Icon(it.icon, size: 20, color: C.navy)),
                    title: Text(it.label, style: const TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
                    subtitle: Row(children: [
                      Icon(_liveOk(it.key) ? Icons.check_circle : Icons.schedule, size: 14, color: _liveOk(it.key) ? C.ok : C.warn),
                      const SizedBox(width: 4),
                      Text(_liveOk(it.key) ? (it.ok ? it.status : 'Ready to save') : 'Pending',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _liveOk(it.key) ? C.ok : C.warn)),
                    ]),
                    children: [_editor(it.key)],
                  ),
                ),
              ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: PButton(_saving ? 'Saving…' : 'SAVE CHANGES', icon: Icons.save, color: const Color(0xFF14958F), onTap: _saving ? null : _save),
          ),
        ),
      ]),
    );
  }
}
