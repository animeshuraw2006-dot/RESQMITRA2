import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

String roleLabel(String r) =>
    r == 'seeker' ? 'Help Seeker' : r == 'rescuer' ? 'Responder' : 'Responder & Help Seeker';

/// Local storage for the registered profile, role, badges, reviews and stats.
/// (Everything is stored on the phone – swap the bodies for Firebase calls to sync.)
class AppState extends ChangeNotifier {
  static final AppState I = AppState._();
  AppState._();
  late SharedPreferences _p;
  final ValueNotifier<bool> online = ValueNotifier(true);

  bool _ready = false;
  bool homeReached = false; // in-memory: true once the Home screen was shown
  bool get ready => _ready;

  Future<void> init() async {
    if (_ready) return;
    _p = await SharedPreferences.getInstance();
    online.value = _p.getBool('online') ?? true;
    if (_p.getString('uid') == null) {
      await _p.setString('uid', 'u${DateTime.now().microsecondsSinceEpoch}');
    }
    if (_p.getInt('since') == null) {
      await _p.setInt('since', DateTime.now().millisecondsSinceEpoch);
    }
    _ready = true;
    notifyListeners();
  }

  void markHome() {
    if (homeReached) return;
    homeReached = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  String get uid => _p.getString('uid') ?? 'u0';
  bool get registered => _ready && (_p.getBool('registered') ?? false);
  String get role => _p.getString('role') ?? 'seeker'; // seeker | rescuer | both
  bool get isRescuer => role != 'seeker';
  Map<String, dynamic> get profile {
    try {
      return (jsonDecode(_p.getString('profile') ?? '{}') as Map).cast<String, dynamic>();
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  List<Map<String, dynamic>> _list(String k) {
    try {
      return (jsonDecode(_p.getString(k) ?? '[]') as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _saveList(String k, List<Map<String, dynamic>> v) => _p.setString(k, jsonEncode(v));

  List<Map<String, dynamic>> get contacts => _list('contacts');
  String get name => (profile['name'] ?? 'ResQMitra user').toString();
  String get phone => (profile['mobile'] ?? '').toString();

  // ── stats / history ──
  List<Map<String, dynamic>> get receivedBadges => _list('rbadges'); // {badge, from, message, time}
  List<Map<String, dynamic>> get reviews => _list('reviews'); // {from, rating, text, time}
  List<Map<String, dynamic>> get responses => _list('responses'); // {type, category, name, address, time}
  int get responded => responses.length;
  int get sent => _p.getInt('sent') ?? 0;
  Set<String> get earnedKeys => receivedBadges.map((e) => (e['badge'] ?? '').toString()).toSet();
  int get daysActive {
    final ms = _p.getInt('since') ?? DateTime.now().millisecondsSinceEpoch;
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms)).inDays + 1;
  }

  double? get rating {
    final r = reviews.map((e) => (e['rating'] as num?)?.toInt() ?? 0).where((x) => x > 0).toList();
    if (r.isEmpty) return null;
    return r.reduce((a, b) => a + b) / r.length;
  }

  Future<void> addResponse(Map<String, dynamic> r) async {
    final l = _list('responses')..add(r);
    await _saveList('responses', l);
    notifyListeners();
  }

  Future<void> incSent() async {
    await _p.setInt('sent', sent + 1);
    notifyListeners();
  }

  /// Called on the RESPONDER's phone when a help seeker sends appreciation.
  Future<void> receiveAppreciation(
      {required String badge, required String from, String message = '', String feedback = '', int rating = 0}) async {
    final now = DateTime.now().toIso8601String();
    if (badge.isNotEmpty) {
      final l = _list('rbadges')..add({'badge': badge, 'from': from, 'message': message, 'time': now});
      await _saveList('rbadges', l);
    }
    if (rating > 0 || feedback.isNotEmpty || message.isNotEmpty) {
      final l = _list('reviews')
        ..add({'from': from, 'rating': rating, 'text': feedback.isNotEmpty ? feedback : message, 'time': now});
      await _saveList('reviews', l);
    }
    notifyListeners();
  }

  // ── profile / role ──
  Future<void> saveRegistration(
      String role, Map<String, dynamic> profile, List<Map<String, dynamic>> contacts) async {
    final clean = Map<String, dynamic>.from(profile)..removeWhere((k, v) => k.endsWith('Bytes'));
    await _p.setString('role', role);
    await _p.setString('profile', jsonEncode(clean));
    await _p.setString('contacts', jsonEncode(contacts));
    await _p.setBool('registered', true);
    notifyListeners();
  }

  Future<void> setRole(String r) async {
    await _p.setString('role', r);
    notifyListeners();
  }

  /// Merges [patch] into the saved profile and rebuilds the emergency-contact list.
  Future<void> updateProfile(Map<String, dynamic> patch) async {
    final p = profile..addAll(patch);
    p.removeWhere((k, v) => k.endsWith('Bytes'));
    await _p.setString('profile', jsonEncode(p));
    final cs = <Map<String, dynamic>>[];
    for (var i = 0; i < 5; i++) {
      final ph = (p['c${i}phone'] ?? '').toString().trim();
      if (ph.isNotEmpty) {
        cs.add({
          'name': (p['c${i}name'] ?? '').toString(),
          'phone': ph,
          'relation': p['c${i}rel'],
          'method': p['c${i}method'] ?? 'Both',
        });
      }
    }
    await _p.setString('contacts', jsonEncode(cs));
    notifyListeners();
  }

  void setOnline(bool v) {
    online.value = v;
    _p.setBool('online', v);
  }

  /// Wipes every saved value (Settings → Reset).
  Future<void> reset() async {
    await _p.clear();
    await _p.setString('uid', 'u${DateTime.now().microsecondsSinceEpoch}');
    await _p.setInt('since', DateTime.now().millisecondsSinceEpoch);
    online.value = true;
    notifyListeners();
  }
}
