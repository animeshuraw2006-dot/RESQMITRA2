import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'responder_service.dart';

/// Firebase SOS gateway. Incident creation and responder claims are authoritative server operations.
class SosRepository {
  SosRepository._();
  static final SosRepository instance = SosRepository._();
  bool get available => Firebase.apps.isNotEmpty;
  CollectionReference<Map<String, dynamic>> get _sos => FirebaseFirestore.instance.collection('sosRequests');

  String _requestId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch}-${List<int>.generate(16, (_) => random.nextInt(16)).map((n) => n.toRadixString(16)).join()}';
  }

  Future<String?> createRequest({
    required String category, required String emergencyType, required String instructions,
    required bool doNotCall, required String bloodGroup, required bool audioRequested,
    required double? latitude, required double? longitude, required double? accuracyMeters,
    required String requesterId, bool highAlert = false,
  }) async {
    if (!available) {
      return null;
    }
    final id = _requestId();
    try {
      await FirebaseFunctions.instance.httpsCallable('createSos').call({
        'requestId': id,
        'category': category,
        'emergencyType': emergencyType,
        'instructions': instructions.trim(),
        'doNotCall': doNotCall,
        'bloodGroup': bloodGroup,
        'audioRequested': audioRequested,
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'highAlert': highAlert,
      });
      return id;
    } on FirebaseFunctionsException {
      // A timeout can occur after the server committed. Reconcile by the same request ID.
      try {
        final snapshot = await _sos.doc(id).get();
        if (snapshot.exists &&
            snapshot.data()?['requesterId'] == FirebaseAuth.instance.currentUser?.uid) {
          return id;
        }
      } catch (_) { /* Keep the original submission error. */ }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getPrivateDetails(String id) async {
    if (!available) {
      return null;
    }
    final snapshot = await FirebaseFirestore.instance.collection('sosPrivate').doc(id).get();
    return snapshot.data(); // Firestore rules restrict this to the owner or assigned responder.
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveRequests() => _sos
      .where('status', whereIn: ['pending', 'accepted', 'en_route', 'arrived'])
      .orderBy('createdAt', descending: true).limit(100).snapshots();

  Future<void> updateStatus(String id, String status) async {
    if (!available) {
      return;
    }
    if (status == 'accepted') {
      await ResponderService.instance.claimIncident(id);
      return;
    }
    const allowed = {'en_route', 'arrived', 'cancelled', 'safe', 'resolved'};
    if (!allowed.contains(status)) {
      throw ArgumentError('Invalid SOS status');
    }
    await ResponderService.instance.updateIncident(id, status);
  }
}
