import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage for the registered profile, role and online/offline mode.
class AppState {
  static final AppState I = AppState._();
  AppState._();
  late SharedPreferences _p;
  final ValueNotifier<bool> online = ValueNotifier(true);

  bool _ready = false;
  Future<void> init() async {
    if (_ready) return;
    _p = await SharedPreferences.getInstance();
    online.value = _p.getBool('online') ?? true;
    if (_p.getString('uid') == null) {
      await _p.setString('uid', 'u${DateTime.now().microsecondsSinceEpoch}');
    }
    _ready = true;
  }

  String get uid => _p.getString('uid') ?? 'u0';
  bool get registered => _p.getBool('registered') ?? false;
  String get role => _p.getString('role') ?? 'seeker'; // seeker | rescuer | both
  bool get isRescuer => role != 'seeker';
  Map<String, dynamic> get profile =>
      (jsonDecode(_p.getString('profile') ?? '{}') as Map).cast<String, dynamic>();
  List<Map<String, dynamic>> get contacts =>
      (jsonDecode(_p.getString('contacts') ?? '[]') as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
  String get name => (profile['name'] ?? 'ResQMitra user').toString();
  String get phone => (profile['mobile'] ?? '').toString();

  Future<void> saveRegistration(
      String role, Map<String, dynamic> profile, List<Map<String, dynamic>> contacts) async {
    await _p.setString('role', role);
    await _p.setString('profile', jsonEncode(profile));
    await _p.setString('contacts', jsonEncode(contacts));
    await _p.setBool('registered', true);
  }

  void setOnline(bool v) {
    online.value = v;
    _p.setBool('online', v);
  }
}
