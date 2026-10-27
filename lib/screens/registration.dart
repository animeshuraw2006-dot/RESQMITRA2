import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'success.dart';

const kStates = [
  'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar',
  'Chandigarh', 'Chhattisgarh', 'Dadra and Nagar Haveli and Daman and Diu', 'Delhi', 'Goa',
  'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir', 'Jharkhand', 'Karnataka',
  'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
  'Mizoram', 'Nagaland', 'Odisha', 'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
];
const kSkills = [
  'First Aid & CPR', 'Emergency Medical Care', 'Fire & Rescue', 'Search & Rescue',
  'Disaster Response', "Women's Safety Support", 'Child Protection', 'Road Accident Support',
  'Psychological First Aid', 'Communication & Coordination', 'Logistics & Transport', 'Other Skills'
];
const kDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const kEquip = ['First Aid Kit', 'AED', 'Ambulance / Transport', 'Rescue Equipment',
  'Fire Safety Equipment', 'Communication Equipment', 'Other'];
const kRelations = ['Father', 'Mother', 'Spouse', 'Brother', 'Sister', 'Son', 'Daughter', 'Friend', 'Neighbour', 'Other'];

/// ONE long scrolling form (no "Next" buttons) – a single SUBMIT button at the end.
class RegistrationScreen extends StatefulWidget {
  final String role; // seeker | rescuer | both
  const RegistrationScreen({super.key, required this.role});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{};
  final _v = <String, dynamic>{'country': 'India'};
  int _contacts = 1, _quals = 0, _n = 0;

  bool get _seeker => widget.role != 'rescuer';
  bool get _rescuer => widget.role != 'seeker';
  TextEditingController _t(String k) => _c.putIfAbsent(k, () => TextEditingController());
  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── helpers ──
  Widget _f(String k, String label,
          {String hint = '', bool req = false, TextInputType? type, int lines = 1, int? max}) =>
      AppField(label: label, ctrl: _t(k), hint: hint, required: req, type: type, maxLines: lines, maxLength: max);
  Widget _dd(String k, String label, List<String> items, {bool req = false}) => AppDropdown(
      label: label, items: items, value: _v[k], required: req, onChanged: (x) => setState(() => _v[k] = x));
  Widget _rg(String k, List<String> o) =>
      RadioRow(options: o, value: _v[k], onChanged: (x) => setState(() => _v[k] = x));
  Widget _ck(String k, String label) =>
      CheckTile(label, _v[k] == true, (x) => setState(() => _v[k] = x));
  Widget _sec(String title, String sub, List<Widget> kids) => SectionCard(++_n, title, sub, kids);

  Future<void> _pick(String k) async {
    final src = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Take a photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera)),
              ListTile(leading: const Icon(Icons.photo_library), title: const Text('Upload from gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery)),
            ])));
    if (src == null) return;
    try {
      final x = await ImagePicker().pickImage(
        source: src,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (x == null) return;

      final bytes = await x.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _snack('Please select an image smaller than 5 MB.');
        return;
      }
      if (!mounted) return;
      setState(() {
        // Keep the path for existing form/submission logic and bytes for
        // cross-platform preview (Image.file is unsupported on Flutter Web).
        _v[k] = x.path;
        _v['${k}Bytes'] = bytes;
      });
    } catch (_) {
      if (mounted) _snack('Unable to select this image. Please try again.');
    }
  }

  Widget _upload(String k, String label) => UploadBox(
        label,
        _v[k],
        () => _pick(k),
        bytes: _v['${k}Bytes'] as Uint8List?,
      );

  Future<void> _dob() async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime(2000),
        firstDate: DateTime(1920),
        lastDate: DateTime.now());
    if (d == null) return;
    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
    setState(() {
      _t('dob').text = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      _t('age').text = '$age';
    });
  }

  Future<void> _verify(String key, String target) async {
    if (key != 'mobile') return;
    final phone = target.replaceAll(RegExp(r'\D'), '');
    if (phone.length != 10) return _snack('Enter a valid 10-digit Indian mobile number');
    final sent = await Api.I.sendPhoneOtp(phone);
    if (!mounted) return;
    if (!sent.ok) {
      return _snack(sent.data['error']?.toString() ??
          'Could not send OTP. Check the backend and Renflair configuration.');
    }
    final code = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Verify +91 $phone'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter the verification code sent to your mobile number.'),
          const SizedBox(height: 8),
          TextField(
            controller: code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'SMS verification code'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, code.text.trim()), child: const Text('Verify')),
        ],
      ),
    );
    code.dispose();
    if (entered == null || entered.isEmpty || !mounted) return;
    final result = await Api.I.verifyPhoneOtp(phone, entered);
    if (!mounted) return;
    if (result.ok) {
      setState(() {
        _v['mobileV'] = true;
        _v['verifiedMobile'] = phone;
      });
      _snack('Phone number verified successfully');
    } else {
      _snack(result.data['error']?.toString() ?? 'OTP verification failed. Please try again.');
    }
  }

  Future<void> _gps() async {
    final p = await LocationService.current();
    if (p == null) return _snack('Turn on location and allow the permission');
    final a = await LocationService.address(p.latitude, p.longitude);
    setState(() {
      _v['lat'] = p.latitude;
      _v['lng'] = p.longitude;
      _v['addr'] = a;
    });
  }

  Future<void> _time(String k) async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (t != null) setState(() => _v[k] = t.format(context));
  }

  Widget _phone(String k, String label, {bool req = false, String? verifyKey}) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: AppField(
                  label: label,
                  ctrl: _t(k),
                  required: req,
                  type: TextInputType.phone,
                  maxLength: 10,
                  hint: '98765 43210',
                  prefix: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 6),
                      child: Text('🇮🇳 +91', style: TextStyle(fontSize: 14))),
                  validator: (s) {
                    if (!req && (s == null || s.isEmpty)) return null;
                    return (s == null || s.length != 10) ? 'Enter 10 digits' : null;
                  })),
          if (verifyKey == 'mobile') ...[
            const SizedBox(width: 8),
            Padding(
                padding: const EdgeInsets.only(top: 25),
                child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: C.royal, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => _verify(verifyKey, _t(k).text),
                        child: const Text('Send OTP')))),
          ],
        ]),
      );

  // ── sections ──
  Widget _personal() => _sec('Personal Details', 'Help us know you better', [
        Center(
            child: Column(children: [
          GestureDetector(
              onTap: () => _pick('photo'),
              child: Stack(children: [
                CircleAvatar(
                    radius: 44,
                    backgroundColor: C.field,
                    backgroundImage: _v['photoBytes'] != null
                        ? MemoryImage(_v['photoBytes'] as Uint8List)
                        : null,
                    child: _v['photoBytes'] == null
                        ? const Icon(Icons.person, size: 48, color: C.grey)
                        : null),
                const Positioned(
                    right: 0, bottom: 0,
                    child: CircleAvatar(radius: 14, backgroundColor: C.royal,
                        child: Icon(Icons.photo_camera, size: 14, color: Colors.white))),
              ])),
          const SizedBox(height: 8),
          const Text('Add / Update Photo', style: TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
          const Text('Take a live photo or upload a clear image', style: TextStyle(fontSize: 12, color: C.grey)),
          const SizedBox(height: 14),
        ])),
        _f('name', 'Full Name', req: true, hint: 'Enter your full name'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: AppField(label: 'Date of Birth', ctrl: _t('dob'), required: true,
              readOnly: true, hint: 'DD/MM/YYYY', onTap: _dob, suffix: const Icon(Icons.calendar_today, size: 18))),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: AppField(label: 'Age', ctrl: _t('age'), readOnly: true, hint: 'Auto calculated')),
        ]),
        const Text('Gender (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.navy)),
        const SizedBox(height: 8),
        _rg('gender', ['Male', 'Female', 'Other', 'Prefer not to say']),
        if (_seeker && widget.role == 'seeker')
          _dd('userType', 'User Type', ['Adult', 'Child', 'Senior Citizen', 'Person with Disability'], req: true),
        _dd('lang', 'Preferred Language', ['English', 'Hindi', 'Bengali', 'Tamil', 'Telugu', 'Malayalam', 'Kannada', 'Marathi', 'Gujarati', 'Punjabi', 'Odia', 'Urdu', 'Nicobarese'], req: true),
        _dd('country', 'Country', ['India'], req: true),
      ]);

  Widget _contactVerify() => _sec('Contact Verification', 'Verify your phone number. Email and emergency contacts do not require OTP.', [
        _phone('mobile', 'Mobile Number', req: true, verifyKey: 'mobile'),
        if (_v['mobileV'] == true) const OkChip('Mobile number verified'),
        _phone('altMobile', 'Alternate Mobile Number (Optional)'),
        AppField(label: 'Email Address', ctrl: _t('email'), required: true, type: TextInputType.emailAddress,
            hint: 'you@example.com',
            validator: (s) => (s == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) ? 'Enter a valid email' : null),
        AppField(label: 'Confirm Email Address', ctrl: _t('email2'), required: true, hint: 'you@example.com',
            validator: (s) => s != _t('email').text ? 'Emails do not match' : null),
      ]);

  Widget _addrFields(String p) => Column(children: [
        _f('${p}house', 'House/Flat No.', req: true),
        _f('${p}street', 'Street / Locality', req: true),
        _f('${p}city', 'Village / Town / City', req: true),
        _f('${p}district', 'District', req: true),
        _dd('${p}state', 'State/UT', kStates, req: true),
        _f('${p}pin', 'PIN Code', req: true, type: TextInputType.number, max: 6),
      ]);

  Widget _address() => _sec('Address & Location', 'Provide your permanent and current address', [
        const Text('A. Permanent Address', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
        const SizedBox(height: 10),
        _addrFields('p'),
        const Text('B. Current Address', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
        _ck('same', 'Same as permanent address'),
        const SizedBox(height: 8),
        if (_v['same'] != true) _addrFields('c'),
        const Text('C. Verify Current Location (GPS)', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
        const SizedBox(height: 10),
        PButton('Verify My Location', icon: Icons.my_location, onTap: _gps),
        if (_v['lat'] != null) ...[
          const SizedBox(height: 10),
          Text('Lat: ${(_v['lat'] as double).toStringAsFixed(4)}   Long: ${(_v['lng'] as double).toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12)),
          if ((_v['addr'] ?? '').toString().isNotEmpty) Text(_v['addr'], style: const TextStyle(fontSize: 12, color: C.grey)),
          const SizedBox(height: 8),
          MiniMap(_v['lat'], _v['lng']),
          const SizedBox(height: 8),
          const OkChip('Location verified'),
        ],
      ]);

  Widget _contact(int i) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Contact ${i + 1} ${i == 0 ? "(Required)" : "(Optional)"}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
          const Spacer(),
          if (i > 0)
            IconButton(icon: const Icon(Icons.delete_outline, color: C.royal),
                onPressed: () => setState(() { _contacts--; })),
        ]),
        const SizedBox(height: 8),
        _f('c${i}name', 'Full Name', req: i == 0, hint: 'Enter name'),
        _dd('c${i}rel', 'Relationship', kRelations, req: i == 0),
        _phone('c${i}phone', 'Mobile Number', req: i == 0, verifyKey: 'c$i'),
        
        _phone('c${i}alt', 'Alternate Number (Optional)'),
        _f('c${i}email', 'Email (Optional)', type: TextInputType.emailAddress),
        const Text('Preferred Contact Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.navy)),
        const SizedBox(height: 8),
        _rg('c${i}method', ['Call', 'SMS', 'Both']),
        const Divider(),
      ]);

  Widget _emergency() => _sec('Emergency Contacts', 'We will contact your trusted person in an emergency', [
        for (var i = 0; i < _contacts; i++) _contact(i),
        if (_contacts < 5)
          OutlinedButton.icon(
              onPressed: () => setState(() => _contacts++),
              icon: const Icon(Icons.add), label: const Text('Add Another Contact')),
      ]);

  Widget _identity(bool req) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _dd('docType', 'Document Type', ['Aadhaar Card', 'Voter ID', 'Driving Licence', 'Passport', 'PAN Card'], req: req),
        _upload('docPhoto', 'Tap to upload or take photo'),
        if (req) ...[
          const Text('Profile Photograph', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.navy)),
          const SizedBox(height: 6),
          _upload('profilePhoto', 'Tap to upload or take photo'),
          const Text('Qualification Certificates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.navy)),
          const SizedBox(height: 6),
          _upload('certDoc', 'Tap to upload certificates'),
          _dd('bg', 'Background Check (Optional)', ['Not Required', 'Police clearance available', 'Consent to background check']),
        ],
        OkChip(_v['docPhoto'] != null ? 'Verification Status: Pending review' : 'Verification Status: Not Verified', ok: false),
      ]);

  Widget _medical() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _dd('blood', 'Blood Group', ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown']),
        if (_rescuer) ...[
          const Text('Ready to donate blood in emergency?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.navy)),
          const SizedBox(height: 8),
          _rg('donate', ['Yes', 'No']),
        ],
        _f('allergies', 'Allergies (Optional)', hint: 'e.g. penicillin, nuts'),
        _f('conditions', 'Medical Conditions (Optional)'),
        _f('meds', 'Current Medication (Optional)'),
        _f('disability', 'Disability / Accessibility Needs (Optional)'),
        _f('safety', 'Special Safety Instructions (Optional)', lines: 2),
      ]);

  Widget _education() => _sec('Education & Qualifications', 'Share your education and professional details', [
        _dd('qual', 'Highest Qualification', ['Below 10th', '10th', '12th', 'Diploma', 'Graduate', 'Post Graduate', 'Doctorate'], req: true),
        _f('course', 'Course Name (Optional)'),
        _f('institution', 'Institution Name (Optional)'),
        _dd('year', 'Year of Completion (Optional)', [for (var y = DateTime.now().year; y >= 1970; y--) '$y']),
        const Text('Upload Certificates (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.navy)),
        const SizedBox(height: 6),
        _upload('eduCert', 'Tap to upload or take photo'),
        const Text('B. Professional Qualifications', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
        const SizedBox(height: 8),
        for (var i = 0; i < _quals; i++) _f('pq$i', 'Qualification ${i + 1}'),
        OutlinedButton.icon(onPressed: () => setState(() => _quals++),
            icon: const Icon(Icons.add), label: const Text('Add Qualification')),
      ]);

  Widget _skills() {
    final sel = (_v['skills'] as List<String>?) ?? <String>[];
    return _sec('Skills & Specializations', 'Select your skills and areas of expertise', [
      const Text('Select your skills (multiple selection)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.navy)),
      const SizedBox(height: 6),
      for (final s in kSkills)
        CheckTile(s, sel.contains(s), (x) => setState(() {
              final l = List<String>.from(sel);
              x ? l.add(s) : l.remove(s);
              _v['skills'] = l;
            })),
      const SizedBox(height: 12),
      _dd('exp', 'Experience Level', ['Beginner', 'Intermediate', 'Advanced', 'Expert'], req: true),
      _f('years', 'Years of Experience (Optional)', type: TextInputType.number),
      _f('languages', 'Languages Spoken (Optional)'),
      _f('trainingOrg', 'Training Organization (Optional)'),
      _f('notes', 'Additional Notes (Optional)', lines: 2),
    ]);
  }

  Widget _availability() {
    final days = (_v['days'] as List<String>?) ?? <String>[];
    final eq = (_v['equip'] as List<String>?) ?? <String>[];
    return _sec('Availability & Resources', 'Share when you are available and what resources you have', [
      const Text('A. Service Availability', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
      const SizedBox(height: 8),
      _rg('avail', ['Available', 'Unavailable']),
      const Text('B. Available Days', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
      Wrap(spacing: 14, children: [
        for (final d in kDays)
          SizedBox(width: 78, child: CheckTile(d, days.contains(d), (x) => setState(() {
                final l = List<String>.from(days);
                x ? l.add(d) : l.remove(d);
                _v['days'] = l;
              }))),
      ]),
      const SizedBox(height: 10),
      const Text('C. Preferred Hours', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => _time('from'), child: Text('From: ${_v['from'] ?? '09:00 AM'}'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(onPressed: () => _time('to'), child: Text('To: ${_v['to'] ?? '05:00 PM'}'))),
      ]),
      const SizedBox(height: 4),
      const Text('Time zone: IST (GMT+5:30)', style: TextStyle(fontSize: 12, color: C.grey)),
      const SizedBox(height: 12),
      _f('serviceArea', 'Service Area (Optional)', hint: 'Area / city / locality'),
      _f('maxKm', 'Maximum Travel Distance (km)', req: true, type: TextInputType.number),
      const Text('E. Equipment / Resources (Optional)', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
      for (final e in kEquip)
        CheckTile(e, eq.contains(e), (x) => setState(() {
              final l = List<String>.from(eq);
              x ? l.add(e) : l.remove(e);
              _v['equip'] = l;
            })),
    ]);
  }

  Widget _review() {
    Widget row(String t, bool done) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600))),
          Icon(done ? Icons.check_circle : Icons.schedule, size: 18, color: done ? C.ok : C.warn),
          const SizedBox(width: 4),
          Text(done ? 'Completed' : 'Pending',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: done ? C.ok : C.warn)),
        ]));
    bool has(String k) => _t(k).text.trim().isNotEmpty;
    return _sec('Review & Consent', 'Please review your details before submitting', [
      row('Personal Details', has('name') && has('dob')),
      row('Phone Verification', _v['mobileV'] == true),
      row('Address & Location', has('phouse') && _v['lat'] != null),
      row('Emergency Contacts', has('c0name') && has('c0phone')),
      row('Medical Information', has('allergies') || has('conditions') || _v['blood'] != null),
      if (_rescuer) row('Education & Qualifications', _v['qual'] != null),
      if (_rescuer) row('Skills & Specializations', ((_v['skills'] as List?) ?? []).isNotEmpty),
      if (_rescuer) row('Availability & Resources', has('maxKm')),
      row('Identity & Documents', _v['docPhoto'] != null),
      const Divider(),
      _ck('terms', 'I agree to the Terms and Conditions'),
      _ck('privacy', 'I agree to the Privacy Policy'),
      if (_rescuer) _ck('conduct', 'I agree to the Volunteer Code of Conduct'),
      if (_rescuer) _ck('guidelines', 'I agree to the Emergency Response Guidelines'),
      _ck('locshare', 'I allow location sharing (when required)'),
      const SizedBox(height: 14),
      PButton('Submit Registration', icon: Icons.send, onTap: _submit),
    ]);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return _snack('Please fill the highlighted fields');
    if (_v['mobileV'] != true ||
        _v['verifiedMobile'] != _t('mobile').text.replaceAll(RegExp(r'\D'), '')) {
      return _snack('Verify your current phone number with SMS OTP');
    }
    if (_v['lat'] == null) return _snack('Verify your current location (GPS)');
    if (_rescuer && ((_v['skills'] as List?) ?? []).isEmpty) return _snack('Select at least one skill');
    if (_rescuer && _v['docPhoto'] == null) return _snack('Upload an identity document');
    for (final k in [
      'terms', 'privacy', 'locshare', if (_rescuer) ...['conduct', 'guidelines']
    ]) {
      if (_v[k] != true) return _snack('Please accept all agreements');
    }
    final profile = <String, dynamic>{
      for (final e in _c.entries) e.key: e.value.text.trim(),
      ..._v,
    };
    final contacts = <Map<String, dynamic>>[
      for (var i = 0; i < _contacts; i++)
        if (_t('c${i}phone').text.trim().isNotEmpty)
          {
            'name': _t('c${i}name').text.trim(),
            'phone': _t('c${i}phone').text.trim(),
            'relation': _v['c${i}rel'],
            'method': _v['c${i}method'] ?? 'Both',
          }
    ];
    await AppState.I.saveRegistration(widget.role, profile, contacts);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => SuccessScreen(role: widget.role)), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    _n = 0;
    final title = widget.role == 'seeker'
        ? 'Help Seeker Registration'
        : widget.role == 'rescuer' ? 'Rescuer Registration' : 'Unified Registration';
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('')),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), children: [
          Center(child: Image.asset('assets/logo.jpeg', height: 110)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.navy)),
          const SizedBox(height: 6),
          const Text('Fill in the details below. One account · Multiple roles · Complete safety.',
              style: TextStyle(fontSize: 14, color: C.grey)),
          const SizedBox(height: 14),
          for (final t in ['To verify your identity and contact information', 'To find you quickly in an emergency', 'To connect you with trusted responders'])
            Padding(padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [const Icon(Icons.check_circle, size: 18, color: C.royal), const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(fontSize: 13)))])),
          const SizedBox(height: 16),
          _personal(),
          _contactVerify(),
          _address(),
          _emergency(),
          if (widget.role == 'seeker')
            _sec('Identity & Medical Information', 'Optional but helps us provide better assistance',
                [const Text('A. Identity Verification (Optional)', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)), const SizedBox(height: 10), _identity(false), const Text('B. Medical Information (Optional)', style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)), const SizedBox(height: 10), _medical()])
          else
            _sec('Medical & Accessibility Information', 'Optional', [_medical()]),
          if (_rescuer) _education(),
          if (_rescuer) _skills(),
          if (_rescuer) _availability(),
          if (_rescuer) _sec('Identity & Document Verification', 'Upload required documents for verification', [_identity(true)]),
          _review(),
        ]),
      ),
    );
  }
}
