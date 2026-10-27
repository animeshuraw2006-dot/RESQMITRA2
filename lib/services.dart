import 'dart:async';
import 'package:another_telephony/telephony.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'config.dart';
import 'state.dart';

// ───────────────────────── Location ─────────────────────────
class LocationService {
  static Future<Position?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)));
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  static Future<String> address(double lat, double lng) async {
    try {
      final p = (await placemarkFromCoordinates(lat, lng)).first;
      return [p.street, p.subLocality, p.locality]
          .where((e) => e != null && e.isNotEmpty)
          .join(', ');
    } catch (_) {
      return '';
    }
  }

  static String mapsLink(double lat, double lng) => 'https://maps.google.com/?q=$lat,$lng';
}

// ───────────────────────── Siren / Flash ─────────────────────────
class SirenService {
  static final AudioPlayer _p = AudioPlayer();
  static final AudioPlayer _alert = AudioPlayer();
  static final _ctx = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: true,
      stayAwake: true,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
  );

  /// Loud looping siren – stopped by tapping anywhere on the siren screen.
  static Future<void> start() async {
    await _p.setAudioContext(_ctx);
    await _p.setReleaseMode(ReleaseMode.loop);
    await _p.setVolume(1.0);
    await _p.play(AssetSource('siren.ogg'));
  }

  static Future<void> stop() async => _p.stop();

  /// Short siren used for "new emergency alert" notifications to responders.
  static Future<void> alertBeep() async {
    await _alert.setAudioContext(_ctx);
    await _alert.setReleaseMode(ReleaseMode.stop);
    await _alert.setVolume(1.0);
    await _alert.play(AssetSource('siren.ogg'));
    Timer(const Duration(seconds: 4), () => _alert.stop());
  }
}

class FlashService {
  static final ValueNotifier<bool> on = ValueNotifier(false);
  static Future<void> toggle() async {
    try {
      if (on.value) {
        await TorchLight.disableTorch();
        on.value = false;
      } else {
        await TorchLight.enableTorch();
        on.value = true;
      }
    } catch (_) {}
  }
}

// ───────────────────────── SMS / Call / Maps ─────────────────────────
class SmsService {
  /// Sends [body] to every saved emergency contact. Uses direct sending on Android
  /// (needs SMS permission) and falls back to opening the SMS app.
  static Future<void> toContacts(String body) async {
    final nums = AppState.I.contacts
        .map((c) => (c['phone'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
    if (nums.isEmpty) return;
    try {
      final t = Telephony.instance;
      final ok = await t.requestSmsPermissions;
      if (ok == true) {
        for (final n in nums) {
          await t.sendSms(to: n, message: body, isMultipart: true);
        }
        return;
      }
    } catch (_) {}
    await launchUrl(Uri.parse('sms:${nums.join(',')}?body=${Uri.encodeComponent(body)}'));
  }
}

Future<void> dial(String number) =>
    launchUrl(Uri(scheme: 'tel', path: number));
Future<void> navigateTo(double lat, double lng) => launchUrl(
    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
    mode: LaunchMode.externalApplication);

// ───────────────────────── SOS model + alert hub ─────────────────────────
class Sos {
  final String id, userId, category, type, name, phone;
  final bool highAlert, doNotCall;
  final DateTime time;
  String desc, address;
  double lat, lng;
  List<String> tags;
  String? photo, audio, responder, remoteId; // remoteId = id on the server
  Map<String, String> details;
  int stage = 0; // 0 received · 1 assigned · 2 on the way · 3 arrived · 4 provided
  bool cancelled = false;
  Sos({
    required this.id,
    required this.userId,
    required this.category,
    required this.type,
    required this.name,
    required this.phone,
    required this.lat,
    required this.lng,
    this.address = '',
    this.desc = '',
    this.tags = const [],
    this.highAlert = false,
    this.doNotCall = false,
    this.photo,
    this.audio,
    this.details = const {},
    DateTime? at,
  }) : time = at ?? DateTime.now();

  String get smsText =>
      'ResQMitra SOS (${highAlert ? "HIGH ALERT - " : ""}$type). $name needs help'
      '${desc.isEmpty ? "" : ": $desc"}. Location: ${LocationService.mapsLink(lat, lng)}'
      '${phone.isEmpty ? "" : " Phone: $phone"}'
      '${details.isEmpty ? "" : " | ${details.entries.map((e) => "${e.key}: ${e.value}").join(", ")}"}';
}

/// Thanks / badge / rating sent by a help seeker after the SOS is closed.
class Appreciation {
  final String sosId, from, badgeKey, message, feedback;
  final int rating;
  final DateTime time;
  Appreciation({
    required this.sosId,
    required this.from,
    this.badgeKey = '',
    this.message = '',
    this.feedback = '',
    this.rating = 0,
  }) : time = DateTime.now();
}

/// Connects help seekers and responders.
/// Local behaviour (siren pop-up, streams) is unchanged; when the app is built with
/// --dart-define=API_BASE=… every action is ALSO sent to the Neon-backed API, and online
/// responders poll the API so alerts and badges reach OTHER phones.
class AlertService extends ChangeNotifier {
  static final AlertService I = AlertService._();
  AlertService._();

  final _c = StreamController<Sos>.broadcast();
  Stream<Sos> get stream => _c.stream;
  Sos? mine; // SOS sent from this phone
  Sos? active; // alert shown to this phone when acting as responder

  final _a = StreamController<Appreciation>.broadcast();
  Stream<Appreciation> get appreciations => _a.stream;

  static final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  // ───────────── help seeker side ─────────────
  void dispatch(Sos s) {
    mine = s;
    AppState.I.incSent();
    _c.add(s);
    notifyListeners();
    _push(s);
  }

  /// Sends the SOS to the server. Retries (the alert is life-critical), then uploads
  /// the photo / voice note afterwards so they never delay the alert.
  Future<void> _push(Sos s) async {
    if (!kBackendOn) return;
    for (var i = 0; i < 6 && s.remoteId == null; i++) {
      if (AppState.I.token.isEmpty) {
        await AppState.I.syncToServer(); // first-time account creation if it never finished
      }
      if (AppState.I.token.isNotEmpty) {
        final r = await Api.I.createSos({
          'client_ref': s.id,
          'category': s.category,
          'type': s.type,
          'lat': s.lat,
          'lng': s.lng,
          'address': s.address,
          'description': s.desc,
          'tags': s.tags,
          'details': s.details,
          'high_alert': s.highAlert,
          'do_not_call': s.doNotCall,
        });
        if (r.ok) {
          s.remoteId = r.data['id']?.toString();
          break;
        }
      }
      await Future.delayed(const Duration(seconds: 4));
    }
    final id = s.remoteId;
    if (id == null) return;
    final photo = (s.photo != null && !s.photo!.startsWith('http')) ? await Api.I.uploadFile(s.photo!, 'sos_photo') : null;
    final audio = s.audio != null ? await Api.I.uploadFile(s.audio!, 'sos_audio') : null;
    if (photo != null || audio != null) await Api.I.attachSosFiles(id, photo: photo, audio: audio);
    _watchMine(s);
  }

  Timer? _mineTimer;

  /// The seeker's phone follows the rescue progress (assigned → on the way → arrived).
  void _watchMine(Sos s) {
    _mineTimer?.cancel();
    _mineTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
      final id = s.remoteId;
      if (id == null || s.cancelled) return t.cancel();
      final r = await Api.I.getSos(id);
      if (!r.ok) return;
      final stage = (r.data['stage'] as num?)?.toInt() ?? s.stage;
      final name = r.data['responder_name']?.toString();
      if (stage != s.stage || name != s.responder) {
        s.stage = stage;
        if (name != null) s.responder = name;
        notifyListeners();
      }
      final st = r.data['status']?.toString();
      if (stage >= 4 || st == 'cancelled' || st == 'expired') t.cancel();
    });
  }

  void cancel(Sos s) {
    s.cancelled = true;
    _mineTimer?.cancel();
    final id = s.remoteId;
    if (id != null) Api.I.cancelSos(id);
    notifyListeners();
  }

  /// Thanks / badge / rating for the responder. With a server the responder's phone receives it
  /// by polling; if that is impossible (offline, no responder yet) it is delivered locally.
  Future<void> sendAppreciation(Appreciation a) async {
    if (Api.I.on && _uuid.hasMatch(a.sosId)) {
      final r = await Api.I.sendAppreciation({
        'sos_id': a.sosId,
        'badge_key': a.badgeKey,
        'message': a.message,
        'feedback': a.feedback,
        'rating': a.rating,
      });
      if (r.ok) return;
    }
    _a.add(a);
  }

  // ───────────── responder side ─────────────
  void receive(Sos s) {
    active = s;
    _c.add(s);
    notifyListeners();
  }

  void setStage(Sos s, int stage, {String? responder}) {
    s.stage = stage;
    if (responder != null) s.responder = responder;
    final id = s.remoteId;
    if (id != null) Api.I.setStage(id, stage);
    notifyListeners();
  }

  Timer? _poll;
  bool _busy = false;
  final _seen = <String>{};
  Position? _pos;
  DateTime _posAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Starts/stops polling depending on role + online switch (called by RootOverlay).
  void configurePolling() {
    final want = Api.I.on && AppState.I.isRescuer && AppState.I.online.value;
    if (want && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
      _tick();
    } else if (!want && _poll != null) {
      _poll?.cancel();
      _poll = null;
      _seen.clear();
    }
  }

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      if (DateTime.now().difference(_posAt).inSeconds > 60) {
        _pos = await LocationService.current() ?? _pos;
        _posAt = DateTime.now();
      }
      final r = await Api.I.nearby(_pos?.latitude ?? 0, _pos?.longitude ?? 0);
      if (r.ok) {
        for (final raw in (r.data['items'] as List? ?? const [])) {
          final j = (raw as Map).cast<String, dynamic>();
          final id = j['id'].toString();
          final status = j['status']?.toString();
          final stage = (j['stage'] as num?)?.toInt() ?? 0;
          final cur = active;
          if (cur != null && cur.id == id) {
            // refresh the alert that is already on screen
            final cancelled = status == 'cancelled';
            final photoId = j['photo_file']?.toString();
            final audioId = j['audio_file']?.toString();
            final nextPhoto = (photoId != null && photoId.isNotEmpty) ? Api.I.fileUrl(photoId) : cur.photo;
            final nextAudio = (audioId != null && audioId.isNotEmpty) ? Api.I.fileUrl(audioId) : cur.audio;
            final changed = cur.stage != stage || cur.cancelled != cancelled ||
                cur.responder != j['responder_name'] || cur.photo != nextPhoto || cur.audio != nextAudio;
            cur.stage = stage > cur.stage ? stage : cur.stage;
            cur.cancelled = cancelled;
            cur.responder = j['responder_name']?.toString() ?? cur.responder;
            cur.photo = nextPhoto;
            cur.audio = nextAudio;
            if (changed) notifyListeners();
            _seen.add(id);
            continue;
          }
          if (_seen.contains(id)) continue;
          _seen.add(id);
          final s = _fromJson(j);
          final fresh = DateTime.now().difference(s.time).inMinutes < 15;
          if (status == 'active' && stage == 0 && fresh) receive(s); // → siren pop-up
        }
      }
      final ap = await Api.I.fetchAppreciations();
      if (ap.ok) {
        for (final raw in (ap.data['items'] as List? ?? const [])) {
          final j = (raw as Map).cast<String, dynamic>();
          _a.add(Appreciation(
            sosId: (j['sos_id'] ?? '').toString(),
            from: (j['from_name'] ?? 'A help seeker').toString(),
            badgeKey: (j['badge_key'] ?? '').toString(),
            message: (j['message'] ?? '').toString(),
            feedback: (j['feedback'] ?? '').toString(),
            rating: (j['rating'] as num?)?.toInt() ?? 0,
          ));
        }
      }
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  Sos _fromJson(Map<String, dynamic> j) {
    final s = Sos(
      id: j['id'].toString(),
      userId: (j['user_id'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      type: (j['type'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      lat: (j['lat'] as num?)?.toDouble() ?? 0,
      lng: (j['lng'] as num?)?.toDouble() ?? 0,
      address: (j['address'] ?? '').toString(),
      desc: (j['description'] ?? '').toString(),
      tags: [for (final t in (j['tags'] as List? ?? const [])) t.toString()],
      highAlert: j['high_alert'] == true,
      doNotCall: j['do_not_call'] == true,
      photo: j['photo_file'] != null ? Api.I.fileUrl(j['photo_file'].toString()) : null,
      audio: j['audio_file'] != null ? Api.I.fileUrl(j['audio_file'].toString()) : null,
      details: {for (final e in ((j['details'] as Map?) ?? const {}).entries) e.key.toString(): e.value.toString()},
      at: DateTime.tryParse((j['created_at'] ?? '').toString())?.toLocal(),
    );
    s.remoteId = s.id;
    s.stage = (j['stage'] as num?)?.toInt() ?? 0;
    s.cancelled = j['status'] == 'cancelled';
    s.responder = j['responder_name']?.toString();
    return s;
  }
}
