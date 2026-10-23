import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_bootstrap.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  Future<void> initializeAndSaveToken() async {
    if (!FirebaseBootstrap.enabled) return;
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (token != null && user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    _messaging.onTokenRefresh.listen((newToken) async {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) await FirebaseFirestore.instance.collection('users').doc(current.uid)
        .set({'fcmToken': newToken, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    });
  }
}
