import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_bootstrap.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> register({required String email, required String password,
    required String fullName, required String role, required String phone}) async {
    if (!FirebaseBootstrap.enabled) throw StateError('Firebase is not configured. Follow BACKEND_SETUP.md first.');
    final result = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = result.user!;
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid, 'fullName': fullName.trim(), 'email': email.trim().toLowerCase(),
      'phone': phone.trim(), 'role': role, 'isResponderOnline': false,
      'createdAt': FieldValue.serverTimestamp(), 'profileVersion': 1,
    });
    return result;
  }

  Future<UserCredential> signIn({required String email, required String password}) {
    if (!FirebaseBootstrap.enabled) throw StateError('Firebase is not configured. Follow BACKEND_SETUP.md first.');
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }
  User? get currentUser => FirebaseBootstrap.enabled ? _auth.currentUser : null;
  Future<void> signOut() async { if (FirebaseBootstrap.enabled) await _auth.signOut(); }
}
