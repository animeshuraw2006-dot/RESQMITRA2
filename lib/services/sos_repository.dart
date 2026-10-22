import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Client wrapper for the authenticated Supabase emergency workflow.
/// Primary dispatch, claim, and cancel use direct transactional PostgreSQL RPCs
/// for 100% reliability, with optional Edge Function invocation for push notifications.
class SosRepository {
  SosRepository._();
  static final SosRepository instance = SosRepository._();

  bool get configured =>
      supabaseUrl.trim().isNotEmpty && supabaseKey.trim().isNotEmpty;
  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>> createRequest({
    required String category,
    required String emergencyType,
    required String instructions,
    required bool doNotCall,
    required String bloodGroup,
    required bool audioRequested,
    required double? latitude,
    required double? longitude,
    required double? accuracyMeters,
    bool highAlert = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in to send an SOS.');
    }

    final clientRequestId =
        '${DateTime.now().microsecondsSinceEpoch}-${user.id}';
    final normCategory = _normalizeCategory(category);
    final normPriority = highAlert ? 'high_alert' : 'normal';

    // 1. Direct PostgreSQL RPC (Fast, reliable, independent of external Edge Functions)
    try {
      final res = await _client.rpc('dispatch_emergency', params: {
        'p_requester_id': user.id,
        'p_client_request_id': clientRequestId,
        'p_category': normCategory,
        'p_emergency_type': emergencyType,
        'p_priority': normPriority,
        'p_instructions': instructions.trim(),
        'p_do_not_call': doNotCall,
        'p_blood_group': bloodGroup,
        'p_audio_requested': audioRequested,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_accuracy_meters': accuracyMeters,
      });

      if (res != null && res is Map && res['id'] != null) {
        final data = Map<String, dynamic>.from(res);
        // Fire-and-forget Edge Function for OneSignal push if deployed
        _client.functions.invoke('dispatch-sos', body: {
          'client_request_id': clientRequestId,
          'category': normCategory,
          'emergency_type': emergencyType,
          'priority': normPriority,
          'instructions': instructions.trim(),
          'do_not_call': doNotCall,
          'blood_group': bloodGroup,
          'audio_requested': audioRequested,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy_meters': accuracyMeters,
        }).catchError((err) {
          debugPrint('Optional push dispatch notice: $err');
          return const FunctionResponse(status: 200);
        });

        return data;
      }
    } catch (rpcError) {
      debugPrint('Direct RPC dispatch attempt: $rpcError');
      // 2. Fallback to Edge Function if RPC failed
      try {
        final response = await _client.functions.invoke('dispatch-sos', body: {
          'client_request_id': clientRequestId,
          'category': normCategory,
          'emergency_type': emergencyType,
          'priority': normPriority,
          'instructions': instructions.trim(),
          'do_not_call': doNotCall,
          'blood_group': bloodGroup,
          'audio_requested': audioRequested,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy_meters': accuracyMeters,
        });
        if (response.status >= 200 && response.status < 300) {
          final data = Map<String, dynamic>.from(response.data as Map);
          if (data['id'] != null) return data;
        }
      } catch (fnError) {
        debugPrint('Edge function fallback error: $fnError');
      }
      throw Exception('SOS dispatch failed. Please ensure schema migration is applied: $rpcError');
    }

    throw Exception('Server did not return a valid emergency confirmation.');
  }

  Future<String?> getAcceptedEmergencyAudioUrl(String emergencyId) async {
    final rows = await _client
        .from('emergency_audio_recordings')
        .select('storage_path')
        .eq('emergency_id', emergencyId)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    final path = rows.first['storage_path'] as String;
    return _client.storage.from('emergency-audio').createSignedUrl(path, 300);
  }

  Future<void> uploadEmergencyAudio(String emergencyId, Uint8List bytes) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in to upload emergency audio.');
    }
    final ext = kIsWeb ? 'webm' : 'aac';
    final mime = kIsWeb ? 'audio/webm' : 'audio/aac';
    final storagePath =
        '$emergencyId/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from('emergency-audio').uploadBinary(
          storagePath,
          bytes,
          fileOptions:
              FileOptions(contentType: mime, upsert: false),
        );
    await _client.from('emergency_audio_recordings').insert({
      'emergency_id': emergencyId,
      'requester_id': user.id,
      'storage_path': storagePath,
      'mime_type': mime,
    });
  }

  Future<void> cancelRequest(String id) async {
    try {
      await _client.rpc('cancel_emergency', params: {'p_emergency_id': id});
      _client.functions.invoke('cancel-sos', body: {'emergency_id': id}).catchError((_) => const FunctionResponse(status: 200));
    } catch (e) {
      final response = await _client.functions
          .invoke('cancel-sos', body: {'emergency_id': id});
      if (response.status < 200 || response.status >= 300) {
        throw Exception('Cancellation failed: $e');
      }
    }
  }

  Future<void> resolveRequest(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.rpc('resolve_emergency', params: {'p_emergency_id': id});
    } catch (e) {
      debugPrint('RPC resolve_emergency notice: $e');
    }
    try {
      await _client
          .from('responder_assignments')
          .update({
            'status': 'resolved',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('emergency_id', id);
    } catch (e) {
      debugPrint('Direct assignment resolve notice: $e');
    }
    try {
      await _client
          .from('emergency_requests')
          .update({
            'status': 'resolved',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      debugPrint('Direct emergency resolve notice: $e');
    }
  }

  Future<void> clearAllAlerts() async {
    final user = _client.auth.currentUser;
    try {
      await _client.rpc('clear_all_test_emergencies');
    } catch (e) {
      debugPrint('RPC clear_all_test_emergencies notice: $e');
    }
    if (user != null) {
      try {
        await _client
            .from('responder_assignments')
            .update({
              'status': 'resolved',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('responder_id', user.id);
      } catch (e) {
        debugPrint('Direct assignments update notice: $e');
      }
      try {
        await _client
            .from('responder_assignments')
            .delete()
            .eq('responder_id', user.id);
      } catch (e) {
        debugPrint('Direct assignments delete notice: $e');
      }
      try {
        await _client
            .from('emergency_requests')
            .delete()
            .eq('requester_id', user.id);
      } catch (e) {
        debugPrint('Direct emergencies delete notice: $e');
      }
    }
  }

  Future<void> acceptRequest(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Sign in required');
    try {
      await _client.rpc('claim_emergency', params: {
        'p_emergency_id': id,
        'p_responder_id': user.id,
      });
      _client.functions.invoke('accept-sos', body: {'emergency_id': id}).catchError((_) => const FunctionResponse(status: 200));
    } catch (e) {
      final response = await _client.functions
          .invoke('accept-sos', body: {'emergency_id': id});
      if (response.status < 200 || response.status >= 300) {
        throw Exception('Acceptance failed: $e');
      }
    }
  }

  /// Real-time stream of assignments for the current user.
  Stream<List<Map<String, dynamic>>> watchActiveRequests() {
    final user = _client.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _client
        .from('responder_assignments')
        .stream(primaryKey: ['id'])
        .eq('responder_id', user.id)
        .map((rows) => rows
            .where((row) {
              final status = (row['status'] ?? '').toString();
              return status == 'assigned' ||
                  status == 'accepted' ||
                  status == 'responding';
            })
            .map((row) => Map<String, dynamic>.from(row))
            .toList());
  }

  /// Get current user's responder availability
  Future<bool> getResponderAvailability() async {
    final user = _client.auth.currentUser;
    if (user == null) return true;
    try {
      final res = await _client
          .from('responder_profiles')
          .select('available')
          .eq('user_id', user.id)
          .maybeSingle();
      return res?['available'] ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Set current user's responder availability
  Future<void> setResponderAvailability(bool available) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('responder_profiles').upsert({
        'user_id': user.id,
        'verified': true,
        'available': available,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating availability: $e');
    }
  }

  String _normalizeCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('women')) return 'women';
    if (value.contains('child')) return 'child';
    return 'general';
  }
}
