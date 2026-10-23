import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores only the user's emergency contact list locally in Android Keystore-backed
/// secure storage. Do not upload contacts to Firestore or log them.
class SecureContactsService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'resqmitra_emergency_contacts_v1';

  Future<List<Map<String, String>>> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
  }

  Future<void> save(List<Map<String, String>> contacts) async {
    final sanitized = contacts.map((c) => {
      'name': (c['name'] ?? '').trim().substring(0, (c['name'] ?? '').trim().length > 80 ? 80 : (c['name'] ?? '').trim().length),
      'phone': (c['phone'] ?? '').trim().substring(0, (c['phone'] ?? '').trim().length > 30 ? 30 : (c['phone'] ?? '').trim().length),
    }).where((c) => c['phone']!.isNotEmpty).toList();
    await _storage.write(key: _key, value: jsonEncode(sanitized));
  }
  Future<void> clear() => _storage.delete(key: _key);
}
