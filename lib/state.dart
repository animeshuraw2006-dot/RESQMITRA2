import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'config.dart';

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
    if (registered) unawaited(syncToServer()); // register (if needed) + pull badges/reviews
  }

  void markHome() {
    if (homeReached) return;
    homeReached = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  String get uid => _p.getString('uid') ?? 'u0';
  String get token => _p.getString('token') ?? '';

  Future<void> setAuth(String uid, String token) async {
    await _p.setString('uid', uid);
    await _p.setString('token', token);
    notifyListeners();
  }

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
    unawaited(syncToServer());
  }

  Future<void> setRole(String r) async {
    await _p.setString('role', r);
    notifyListeners();
    unawaited(syncToServer());
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
    unawaited(syncToServer());
  }

  void setOnline(bool v) {
    online.value = v;
    _p.setBool('online', v);
    if (Api.I.on) unawaited(Api.I.presence(v));
  }

  // ───────────── backend sync (Neon via backend/server.js) ─────────────
  bool _syncing = false, _again = false;

  /// Uploads a profile image once (re-uploads only when the file path changes).
  Future<String?> _fileId(String key, String kind) async {
    final path = (profile[key] ?? '').toString();
    if (path.isEmpty) return null;
    final cached = _p.getString('up_$key') ?? '';
    if (cached.startsWith('$path|')) return cached.substring(path.length + 1);
    final id = await Api.I.uploadFile(path, kind);
    if (id != null) await _p.setString('up_$key', '$path|$id');
    return id;
  }

  /// Creates the account on first run, then keeps profile / role / contacts / images in sync.
  Future<void> syncToServer() async {
    if (!kBackendOn || !registered) return;
    if (_syncing) {
      _again = true;
      return;
    }
    _syncing = true;
    try {
      if (token.isEmpty) {
        final r = await Api.I.register(role, profile, contacts);
        if (!r.ok) return; // offline – retried on next app start / next change
        await setAuth(r.data['user_id'].toString(), r.data['token'].toString());
      }
      final photo = await _fileId('photo', 'photo');
      final doc = await _fileId('docPhoto', 'id_doc');
      await Api.I.syncProfile(role, profile, contacts, photoFile: photo, docFile: doc);
      await syncFromServer();
    } finally {
      _syncing = false;
      if (_again) {
        _again = false;
        unawaited(syncToServer());
      }
    }
  }

  /// Replaces the locally cached badges / reviews / responses with the server's copy.
  Future<void> syncFromServer() async {
    if (!Api.I.on) return;
    final r = await Api.I.summary();
    if (!r.ok) return;
    List<Map<String, dynamic>> rows(String k) =>
        ((r.data[k] as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    await _saveList('rbadges', [
      for (final e in rows('badges'))
        {'badge': e['badge_key'], 'from': e['from_name'], 'message': e['message'], 'time': e['created_at']}
    ]);
    await _saveList('reviews', [
      for (final e in rows('reviews'))
        {
          'from': e['from_name'],
          'rating': e['rating'],
          'text': (e['feedback'] ?? '').toString().isNotEmpty ? e['feedback'] : e['message'],
          'time': e['created_at']
        }
    ]);
    await _saveList('responses', [
      for (final e in rows('responses'))
        {'type': e['type'], 'category': e['category'], 'name': e['name'], 'address': e['address'], 'time': e['updated_at']}
    ]);
    await _p.setInt('sent', (r.data['sent'] as num?)?.toInt() ?? sent);
    final since = DateTime.tryParse((r.data['since'] ?? '').toString());
    if (since != null) await _p.setInt('since', since.millisecondsSinceEpoch);
    notifyListeners();
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
