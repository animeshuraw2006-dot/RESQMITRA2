import 'dart:io';
import 'package:flutter/material.dart';

/// Profile photo (saved file path) → ImageProvider, or null when missing.
ImageProvider? avatarProvider(Map<String, dynamic> profile) {
  final path = (profile['photo'] ?? '').toString();
  if (path.isEmpty) return null;
  try {
    final f = File(path);
    if (f.existsSync()) return FileImage(f);
  } catch (_) {}
  return null;
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'R';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  final l = d.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}, '
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
