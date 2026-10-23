import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firebase email/password authentication. No client-side role elevation is exposed.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  bool get configured => Firebase.apps.isNotEmpty;
  User? get currentUser => configured ? FirebaseAuth.instance.currentUser : null;

  Future<UserCredential> register({required String email, required String password}) async {
    if (!configured) {
      throw StateError('Firebase is not configured. Demo sign-in is not a real account.');
    }
    final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    await result.user?.sendEmailVerification();
    return result;
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    if (!configured) {
      throw StateError('Firebase is not configured. Demo sign-in is not a real account.');
    }
    return FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> resetPassword(String email) async {
    if (!configured) {
      throw StateError('Firebase is not configured.');
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    if (configured) {
      await FirebaseAuth.instance.signOut();
    }
  }
}
