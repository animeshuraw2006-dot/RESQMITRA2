import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident.dart';

class IncidentService {
  IncidentService._();

  static final IncidentService instance = IncidentService._();
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Incident>> watchOpenIncidents() {
    return _client
        .from('incidents')
        .stream(primaryKey: ['id'])
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Incident.fromMap).toList(growable: false));
  }

  Stream<Incident?> watchIncident(String id) {
    return _client
        .from('incidents')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : Incident.fromMap(rows.first));
  }

  Future<String> createSos({
    required Position position,
    required String category,
    required bool highRisk,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in before creating an SOS.');

    final row = await _client.from('incidents').insert({
      'created_by': user.id,
      'status': 'open',
      'risk': highRisk ? 'high' : 'standard',
      'category': category,
      'latitude': position.latitude,
      'longitude': position.longitude,
    }).select('id').single();
    return row['id'] as String;
  }

  Future<void> acceptIncident(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in before accepting an SOS.');

    // The SQL RPC atomically claims only incidents that are still open.
    final accepted = await _client.rpc(
      'accept_incident',
      params: {'p_incident_id': id},
    );
    if (accepted != true) {
      throw StateError('This SOS has already been accepted or is unavailable.');
    }
  }

  Future<void> updateStatus(String id, String status) async {
    const allowed = {'en_route', 'arrived', 'completed', 'cancelled'};
    if (!allowed.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported incident status.');
    }
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in before updating an SOS.');

    final updated = await _client.rpc(
      'update_incident_status',
      params: {'p_incident_id': id, 'p_status': status},
    );
    if (updated != true) {
      throw StateError('You are not allowed to change this incident status.');
    }
  }
}
