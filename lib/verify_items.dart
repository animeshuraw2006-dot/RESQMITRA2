import 'package:flutter/material.dart';
import 'state.dart';
import 'theme.dart';

/// One row of the verification checklist (used by the Profile + Verification screens).
class VItem {
  final String key, label, status;
  final IconData icon;
  final bool ok; // true = nothing left to do
  const VItem(this.key, this.label, this.icon, this.status, this.ok);

  Color get color => ok ? C.ok : (status == 'Under review' ? C.blue : C.warn);
}

List<VItem> verificationItems() {
  final p = AppState.I.profile;
  bool has(String k) => (p[k] ?? '').toString().trim().isNotEmpty;
  final skills = p['skills'] is List ? (p['skills'] as List) : const [];
  VItem v(String k, String l, IconData i, bool ok, {String yes = 'Provided', String no = 'Pending'}) =>
      VItem(k, l, i, ok ? yes : no, ok);
  return [
    v('name', 'Full Name', Icons.person, has('name')),
    v('photo', 'Profile Photograph', Icons.photo_camera, has('photo')),
    v('mobile', 'Mobile Number', Icons.phone, p['mobileV'] == true, yes: 'Verified'),
    v('email', 'Email Address', Icons.email, p['emailV'] == true, yes: 'Verified'),
    v('address', 'Permanent Address', Icons.home, has('phouse')),
    v('gps', 'GPS Location', Icons.location_on, p['lat'] != null, yes: 'Verified'),
    v('contact1', 'Emergency Contact 1', Icons.call, has('c0phone'),
        yes: p['c0V'] == true ? 'Verified' : 'Provided'),
    v('contact2', 'Emergency Contact 2', Icons.call, has('c1phone'),
        yes: p['c1V'] == true ? 'Verified' : 'Provided'),
    v('identity', 'Identity Verification', Icons.badge, has('docPhoto'), yes: 'Under review'),
    v('medical', 'Medical Information', Icons.add_circle,
        has('blood') || has('allergies') || has('conditions')),
    if (AppState.I.isRescuer)
      v('skills', 'Skills & Specialisation', Icons.workspace_premium, skills.isNotEmpty),
  ];
}

int completionPercent(List<VItem> items) =>
    items.isEmpty ? 100 : (items.where((e) => e.ok).length * 100 / items.length).round();
