import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Optional API client for the Neon-backed RESQ-MITRA backend.
/// Configure with --dart-define=RESQ_API_BASE_URL=https://your-api.example.com
/// and pass a short-lived token issued by your trusted auth provider.
/// Never put DATABASE_URL, storage secrets, or JWT signing secrets in Flutter.
class ResQMitraBackendApi {
  ResQMitraBackendApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const String baseUrl = String.fromEnvironment('RESQ_API_BASE_URL');

  Uri _uri(String path) {
    if (baseUrl.isEmpty) throw StateError('RESQ_API_BASE_URL is not configured.');
    return Uri.parse(baseUrl).resolve(path);
  }

  Future<Map<String, dynamic>> _request(String method, String path,
      {required String accessToken, Map<String, dynamic>? body}) async {
    final uri = _uri(path);
    final headers = <String, String>{'Accept':'application/json','Authorization':'Bearer $accessToken'};
    if (body != null) headers['Content-Type'] = 'application/json';
    late http.Response response;
    switch (method) {
      case 'GET': response = await _client.get(uri, headers: headers); break;
      case 'POST': response = await _client.post(uri, headers: headers, body: jsonEncode(body ?? {})); break;
      default: throw ArgumentError('Unsupported method');
    }
    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ResQMitraApiException(response.statusCode, decoded['error']?.toString() ?? 'Backend request failed');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createSos({required String accessToken, required String category,
    required String emergencyType, required double latitude, required double longitude,
    String description = '', String address = '', bool highAlert = false, bool doNotCall = false,
    List<String> tags = const [], Map<String, dynamic> extraDetails = const {}}) => _request('POST','/sos',accessToken:accessToken,body:{
      'category':category,'emergency_type':emergencyType,'latitude':latitude,'longitude':longitude,
      'description':description,'address':address,'high_alert':highAlert,'do_not_call':doNotCall,
      'tags':tags,'extra_details':extraDetails,
    });

  Future<List<Map<String, dynamic>>> mySos(String accessToken) async {
    final result = await _request('GET','/sos/mine',accessToken:accessToken);
    return (result['items'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> cancelSos({required String accessToken, required String sosId}) =>
      _request('POST','/sos/$sosId/cancel',accessToken:accessToken);

  Future<Map<String, dynamic>> acceptSos({required String accessToken, required String sosId}) =>
      _request('POST','/sos/$sosId/accept',accessToken:accessToken);

  @visibleForTesting
  void close() => _client.close();
}

class ResQMitraApiException implements Exception {
  const ResQMitraApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ResQMitraApiException($statusCode): $message';
}
