import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/profile_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_card.dart';
import 'permissions_screen.dart';

class RegistrationWizardScreen extends StatefulWidget {
  const RegistrationWizardScreen({super.key, required this.role});
  final String role;

  @override
  State<RegistrationWizardScreen> createState() => _RegistrationWizardScreenState();
}

class _RegistrationWizardScreenState extends State<RegistrationWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = ProfileStorageService();
  final Map<String, String> _data = {};
  int _step = 0;

  final List<String> _titles = [
    'Personal Details',
    'Contact Verification',
    'Address & Location',
    'Emergency Contacts',
    'Medical & Accessibility',
    'Education & Qualifications',
    'Skills & Specializations',
    'Availability & Resources',
    'Identity Verification',
    'Review & Consent',
  ];

  bool get _isResponder => widget.role == 'responder' || widget.role == 'both';

  @override
  Widget build(BuildContext context) {
    final title = _titles[_step];
    return Scaffold(
      appBar: AppBar(
        title: Text('${_step + 1}. $title'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
          if (_step == 0) {
            Navigator.pop(context);
          } else {
            setState(() => _step--);
          }
        }),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LinearProgressIndicator(value: (_step + 1) / _titles.length, minHeight: 6, borderRadius: BorderRadius.circular(10)),
            const SizedBox(height: 14),
            Text('Step ${_step + 1} of ${_titles.length}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            _buildStep(),
            const SizedBox(height: 8),
            if (_step == 9) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _data['termsAccepted'] == 'true',
                onChanged: (v) => setState(() => _data['termsAccepted'] = '${v ?? false}'),
                title: const Text('I agree to the Terms, Privacy Policy and applicable safety guidelines.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
            PrimaryButton(
              label: _step == 9 ? 'Submit Registration' : 'Next',
              onPressed: _next,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _saveDraft, child: const Text('Save draft')),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return SectionCard(title: 'Tell us about yourself', child: Column(children: [
          _field('Full name', required: true),
          _field('Date of birth (DD/MM/YYYY)', required: true),
          _dropdown('Gender', ['Prefer not to say', 'Female', 'Male', 'Other']),
          _dropdown('Preferred language', ['English', 'Hindi', 'Bengali', 'Tamil', 'Other'], required: true),
          _dropdown('Country', ['India', 'Other'], required: true),
        ]));
      case 1:
        return SectionCard(title: 'Verify your contact details', subtitle: 'Demo mode: no real OTP is sent in this starter.', child: Column(children: [
          _field('Mobile number', required: true, keyboard: TextInputType.phone),
          _field('Email address', required: true, keyboard: TextInputType.emailAddress),
          _field('Alternate mobile (optional)', keyboard: TextInputType.phone),
          const Text('Connect a trusted authentication provider to implement real OTP and email verification.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ]));
      case 2:
        return SectionCard(title: 'Permanent and current address', child: Column(children: [
          _field('House / Flat number'),
          _field('Street / Locality', required: true),
          _field('Village / Town / City', required: true),
          _field('District', required: true),
          _field('State / UT', required: true),
          _field('PIN code', required: true, keyboard: TextInputType.number),
          _field('Current address (if different)'),
          Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the permissions page or location feature to capture GPS location.')));
          }, icon: const Icon(Icons.location_on), label: const Text('Location will be requested when needed'))),
        ]));
      case 3:
        return SectionCard(title: 'At least one trusted contact', child: Column(children: [
          _field('Contact full name', required: true),
          _dropdown('Relationship', ['Family', 'Friend', 'Neighbour', 'Colleague', 'Other'], required: true),
          _field('Contact mobile number', required: true, keyboard: TextInputType.phone),
          _field('Contact email (optional)', keyboard: TextInputType.emailAddress),
          _dropdown('Preferred contact method', ['Call', 'SMS', 'Both'], required: true),
          OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Additional contact fields can be added in a future iteration.'))), icon: const Icon(Icons.add), label: const Text('Add another contact')),
        ]));
      case 4:
        return SectionCard(title: 'Optional medical and accessibility details', child: Column(children: [
          _dropdown('Blood group', ['Prefer not to say', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown']),
          _field('Allergies (optional)'),
          _field('Medical conditions (optional)'),
          _field('Current medication (optional)'),
          _field('Disability / accessibility needs (optional)'),
          _field('Special safety instructions (optional)'),
        ]));
      case 5:
        return SectionCard(title: 'Education and qualifications', subtitle: _isResponder ? 'Relevant for responder verification.' : 'Optional unless needed for a selected role.', child: Column(children: [
          _dropdown('Highest qualification', ['Not specified', 'School', 'Higher Secondary', 'Diploma', 'Bachelor degree', 'Master degree', 'Other'], required: _isResponder),
          _field('Course name (optional)'),
          _field('Institution name (optional)'),
          _dropdown('Year of completion', ['Not specified', '2026', '2025', '2024', '2023', 'Earlier']),
          _field('Professional qualifications (optional)'),
        ]));
      case 6:
        return SectionCard(title: 'Skills and specializations', subtitle: _isResponder ? 'Select skills you can safely provide.' : 'Optional for help seekers.', child: Column(children: [
          ...['First Aid & CPR', 'Fire & Rescue', 'Disaster Response', 'Child Protection', 'Psychological First Aid', 'Emergency Medical Care', 'Search & Rescue', 'Women’s Safety Support', 'Road Accident Support', 'Communication & Coordination'].map((skill) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(skill),
            value: _data['skill_$skill'] == 'true',
            onChanged: (v) => setState(() => _data['skill_$skill'] = '${v ?? false}'),
          )),
          _dropdown('Experience level', ['Not specified', 'Beginner', 'Trained volunteer', 'Professional'], required: _isResponder),
          _field('Years of experience (optional)', keyboard: TextInputType.number),
          _field('Languages spoken (optional)'),
        ]));
      case 7:
        return SectionCard(title: 'Availability and resources', subtitle: _isResponder ? 'Required to coordinate responder availability.' : 'Optional for help seekers.', child: Column(children: [
          _dropdown('Service availability', ['Unavailable', 'Available'], required: _isResponder),
          _dropdown('Available days', ['Any day', 'Weekdays', 'Weekends', 'Custom'], required: _isResponder),
          _dropdown('Preferred hours', ['Any time', 'Morning', 'Afternoon', 'Evening', 'Night']),
          _field('Service area (city / locality)', required: _isResponder),
          _dropdown('Maximum travel distance', ['5 km', '10 km', '25 km', '50 km', 'Not specified']),
          ...['First aid kit', 'AED', 'Ambulance / transport', 'Rescue equipment', 'Fire safety equipment', 'Communication equipment'].map((item) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item),
            value: _data['resource_$item'] == 'true',
            onChanged: (v) => setState(() => _data['resource_$item'] = '${v ?? false}'),
          )),
        ]));
      case 8:
        return SectionCard(title: 'Identity and document verification', subtitle: 'Upload and verification provider setup is required before real identity checks.', child: Column(children: [
          _dropdown('Document type', ['Select document', 'Aadhaar card', 'Driving licence', 'Passport', 'Voter ID', 'Other']),
          _field('Document reference (do not enter sensitive ID in demo)'),
          _field('Qualification certificates (optional)'),
          _dropdown('Background check', ['Not requested', 'Required', 'In progress'], required: _isResponder),
          const Text('This starter does not upload documents or verify identity. Configure secure upload storage and a trusted review process before collecting documents.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ]));
      default:
        return SectionCard(title: 'Review your information', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Selected role: ${_roleLabel(widget.role)}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Entered fields: ${_data.entries.where((e) => !e.key.startsWith('skill_') && !e.key.startsWith('resource_') && !e.key.startsWith('terms')).where((e) => e.value.trim().isNotEmpty).length}'),
          const SizedBox(height: 10),
          const Text('Review all details before submission. Contact and identity verification are not performed by this demo.'),
          const SizedBox(height: 10),
          ..._data.entries.where((e) => e.value.trim().isNotEmpty && !e.key.startsWith('skill_') && !e.key.startsWith('resource_')).take(8).map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12)),
          )),
        ]));
    }
  }

  Widget _field(String label, {bool required = false, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: _data[label],
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: '$label${required ? ' *' : ''}'),
        validator: required ? (value) => (value == null || value.trim().isEmpty) ? 'This field is required' : null : null,
        onChanged: (value) => _data[label] = value,
      ),
    );
  }

  Widget _dropdown(String label, List<String> options, {bool required = false}) {
    final current = _data[label];
    final value = options.contains(current) ? current : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: '$label${required ? ' *' : ''}'),
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: (v) => setState(() => _data[label] = v ?? ''),
        validator: required ? (v) => v == null || v.isEmpty ? 'Please select an option' : null : null,
      ),
    );
  }

  Future<void> _saveDraft() async {
    await _storage.saveProfile({'role': widget.role, 'fields': _data, 'registrationStatus': 'draft'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved on this device.')));
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    if (_step < _titles.length - 1) {
      setState(() => _step++);
      return;
    }
    if (_data['termsAccepted'] != 'true') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the terms to continue.')));
      return;
    }
    await _storage.saveProfile({
      'role': widget.role,
      'fields': _data,
      'registrationStatus': 'submitted_demo',
      'submittedAt': DateTime.now().toIso8601String(),
      'verificationStatus': 'pending',
    });
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PermissionsScreen(role: widget.role)));
  }

  String _roleLabel(String role) => switch (role) {
    'helpSeeker' => 'Help Seeker',
    'responder' => 'As Responder',
    _ => 'Both',
  };
}
