import 'package:cloud_functions/cloud_functions.dart';

/// All responder claims and authoritative status transitions are server-side.
class ResponderService {
  ResponderService._();
  static final ResponderService instance = ResponderService._();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> claimIncident(String incidentId) async {
    await _functions.httpsCallable('claimSos').call({'incidentId': incidentId});
  }

  Future<void> updateIncident(String incidentId, String status) async {
    await _functions.httpsCallable('updateSosStatus').call({'incidentId': incidentId, 'status': status});
  }
}
