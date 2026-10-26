import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'config.dart';
import 'state.dart';

/// Result of an API call. status 0 = no network / timeout.
class ApiRes {
  final int status;
  final Map<String, dynamic> data;
  const ApiRes(this.status, [this.data = const {}]);
  bool get ok => status >= 200 && status < 300;
}

/// Thin HTTP client for the ResQMitra API (backend/server.js → Neon PostgreSQL).
/// Every method swallows network errors and returns an [ApiRes], so the UI never crashes
/// and the app keeps working offline.
class Api {
  static final Api I = Api._();
  Api._();

  /// true when a server address is configured AND this phone has an account token.
  bool get on => kBackendOn && AppState.I.ready && AppState.I.token.isNotEmpty;

  Map<String, String> get authHeaders =>
      {if (AppState.I.token.isNotEmpty) 'Authorization': 'Bearer ${AppState.I.token}'};

  Uri _u(String path, [Map<String, String>? q]) => Uri.parse('$kApiBase$path').replace(queryParameters: q);

  Future<ApiRes> _call(String method, String path, {Object? body, Map<String, String>? q, int seconds = 25}) async {
    if (!kBackendOn) return const ApiRes(0);
    try {
      final req = http.Request(method, _u(path, q))
        ..headers.addAll({'Content-Type': 'application/json', ...authHeaders});
      if (body != null) req.body = jsonEncode(body);
      final res = await http.Response.fromStream(await req.send().timeout(Duration(seconds: seconds)));
      Map<String, dynamic> data = {};
      try {
        final d = jsonDecode(res.body);
        if (d is Map) data = d.cast<String, dynamic>();
      } catch (_) {}
      return ApiRes(res.statusCode, data);
    } catch (_) {
      return const ApiRes(0);
    }
  }

  // ── account / profile ──
  Future<ApiRes> register(String role, Map<String, dynamic> profile, List<Map<String, dynamic>> contacts) =>
      _call('POST', '/auth/register', body: {'role': role, 'profile': _strip(profile), 'contacts': contacts}, seconds: 60);

  Future<ApiRes> syncProfile(String role, Map<String, dynamic> profile, List<Map<String, dynamic>> contacts,
          {String? photoFile, String? docFile}) =>
      _call('PUT', '/me/profile',
          body: {'role': role, 'profile': _strip(profile), 'contacts': contacts, 'photo_file': photoFile, 'doc_file': docFile});

  Future<ApiRes> summary() => _call('GET', '/me/summary');
  Future<ApiRes> presence(bool online, {double? lat, double? lng}) =>
      _call('PUT', '/me/presence', body: {'online': online, 'lat': lat, 'lng': lng});

  /// local-only keys (file paths) are never sent in the profile JSON
  Map<String, dynamic> _strip(Map<String, dynamic> p) =>
      Map<String, dynamic>.from(p)..removeWhere((k, v) => k == 'photo' || k == 'docPhoto' || k.endsWith('Bytes'));

  // ── files ──
  String fileUrl(String id) => '$kApiBase/files/$id';

  /// Uploads a local file and returns its server id (or null).
  Future<String?> uploadFile(String path, String kind) async {
    if (!kBackendOn || AppState.I.token.isEmpty) return null;
    try {
      final f = File(path);
      if (!await f.exists()) return null;
      final lower = path.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
              ? 'image/webp'
              : (lower.endsWith('.m4a') || lower.endsWith('.mp4'))
                  ? 'audio/mp4'
                  : lower.endsWith('.aac')
                      ? 'audio/aac'
                      : 'image/jpeg';
      final res = await http
          .post(_u('/files', {'kind': kind}), headers: {...authHeaders, 'Content-Type': mime}, body: await f.readAsBytes())
          .timeout(const Duration(seconds: 90));
      if (res.statusCode >= 200 && res.statusCode < 300) return (jsonDecode(res.body) as Map)['file_id']?.toString();
    } catch (_) {}
    return null;
  }

  /// Downloads a server file (needs the auth header) into a temp file; returns its path.
  Future<String?> downloadFile(String url) async {
    try {
      final res = await http.get(Uri.parse(url), headers: authHeaders).timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) return null;
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/dl_${url.hashCode}.m4a');
      await f.writeAsBytes(res.bodyBytes);
      return f.path;
    } catch (_) {
      return null;
    }
  }

  // ── SOS ──
  Future<ApiRes> createSos(Map<String, dynamic> body) => _call('POST', '/sos', body: body, seconds: 30);
  Future<ApiRes> attachSosFiles(String id, {String? photo, String? audio}) =>
      _call('PATCH', '/sos/$id/files', body: {'photo_file': photo, 'audio_file': audio});
  Future<ApiRes> getSos(String id) => _call('GET', '/sos/$id');
  Future<ApiRes> nearby(double lat, double lng) =>
      _call('GET', '/sos/nearby', q: {'lat': '$lat', 'lng': '$lng', 'radius_km': '50'}, seconds: 15);
  Future<ApiRes> setStage(String id, int stage) => _call('PATCH', '/sos/$id/stage', body: {'stage': stage});
  Future<ApiRes> cancelSos(String id) => _call('POST', '/sos/$id/cancel');

  // ── appreciation ──
  Future<ApiRes> sendAppreciation(Map<String, dynamic> body) => _call('POST', '/appreciations', body: body);
  Future<ApiRes> fetchAppreciations() => _call('GET', '/me/appreciations', seconds: 15);
}
