import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_bootstrap.dart';

class EmergencyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates an authenticated, server-timestamped SOS record. Do not put contact
  /// phone numbers or sensitive medical detail in this document.
  Future<String> createSos({required String type, required Position position,
    String description = '', bool doNotCall = false}) async {
    if (!FirebaseBootstrap.enabled) throw StateError('Firebase is not configured.');
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in before sending a network SOS.');
    final ref = await _db.collection('emergencies').add({
      'helpSeekerUid': user.uid,
      'type': type,
      'description': description.trim().substring(0, description.trim().length > 1000 ? 1000 : description.trim().length),
      'doNotCall': doNotCall,
      'status': 'open',
      'location': GeoPoint(position.latitude, position.longitude),
      'locationAccuracyM': position.accuracy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'acceptedBy': null,
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOpenEmergencies() {
    if (!FirebaseBootstrap.enabled) throw StateError('Firebase is not configured.');
    return _db.collection('emergencies').where('status', isEqualTo: 'open').orderBy('createdAt', descending: true).limit(50).snapshots();
  }

  Future<void> setResponderOnline(bool online, {Position? position, String? fcmToken}) async {
    if (!FirebaseBootstrap.enabled) throw StateError('Firebase is not configured.');
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in first.');
    await _db.collection('responders').doc(user.uid).set({
      'uid': user.uid, 'online': online, 'updatedAt': FieldValue.serverTimestamp(),
      if (position != null) 'location': GeoPoint(position.latitude, position.longitude),
      if (fcmToken != null) 'fcmToken': fcmToken,
    }, SetOptions(merge: true));
    await _db.collection('users').doc(user.uid).set({'isResponderOnline': online}, SetOptions(merge: true));
  }

  Future<void> acceptEmergency(String emergencyId) async {
    if (!FirebaseBootstrap.enabled) throw StateError('Firebase is not configured.');
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in first.');
    await _db.collection('emergencies').doc(emergencyId).update({
      'acceptedBy': user.uid, 'status': 'accepted', 'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
