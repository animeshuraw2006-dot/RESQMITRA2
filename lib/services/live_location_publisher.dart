import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_bootstrap.dart';

/// Publishes location only while explicitly started by a signed-in responder.
/// Stop the stream when the responder goes offline or leaves the active session.
class LiveLocationPublisher {
  StreamSubscription<Position>? _subscription;
  Future<void> start({required String emergencyId}) async {
    if (!FirebaseBootstrap.enabled) throw StateError('Firebase is not configured.');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in first.');
    await stop();
    _subscription = Geolocator.getPositionStream(locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high, distanceFilter: 15)).listen((p) async {
      await FirebaseFirestore.instance.collection('emergencies').doc(emergencyId)
        .collection('liveLocations').doc(uid).set({
          'uid': uid, 'location': GeoPoint(p.latitude, p.longitude),
          'accuracyM': p.accuracy, 'updatedAt': FieldValue.serverTimestamp(),
        });
    });
  }
  Future<void> stop() async { await _subscription?.cancel(); _subscription = null; }
}
