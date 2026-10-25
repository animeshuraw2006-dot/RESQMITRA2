import 'dart:async';
import 'package:another_telephony/telephony.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? photo, audio, responder;
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
  }) : time = DateTime.now();

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

/// In-app hub that connects help seekers and responders.
/// This is an in-memory implementation – replace [dispatch]/[setStage]/[cancel]
/// with Firebase (Firestore + FCM) calls so alerts reach OTHER phones.
class AlertService extends ChangeNotifier {
  static final AlertService I = AlertService._();
  AlertService._();

  final _c = StreamController<Sos>.broadcast();
  Stream<Sos> get stream => _c.stream;
  Sos? mine; // SOS sent from this phone
  Sos? active; // alert shown to this phone when acting as responder

  void dispatch(Sos s) {
    mine = s;
    AppState.I.incSent();
    // TODO(backend): write to Firestore + push FCM to nearby online responders.
    _c.add(s);
    notifyListeners();
  }

  // ── appreciation (help seeker → responder) ──
  final _a = StreamController<Appreciation>.broadcast();
  Stream<Appreciation> get appreciations => _a.stream;

  /// TODO(backend): store in Firestore under the responder's uid + push (FCM) so the
  /// responder's phone shows the badge reveal. Locally it is delivered through a stream.
  void sendAppreciation(Appreciation a) => _a.add(a);

  void receive(Sos s) {
    active = s;
    _c.add(s);
    notifyListeners();
  }

  void setStage(Sos s, int stage, {String? responder}) {
    s.stage = stage;
    if (responder != null) s.responder = responder;
    notifyListeners();
  }

  void cancel(Sos s) {
    s.cancelled = true;
    notifyListeners();
  }
}
