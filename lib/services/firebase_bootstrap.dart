import 'package:firebase_core/firebase_core.dart';

/// Firebase is opt-in until `flutterfire configure` creates platform options.
/// Build with --dart-define=RESQMIRA_FIREBASE=true only after configuration.
class FirebaseBootstrap {
  static bool get enabled => const bool.fromEnvironment('RESQMIRA_FIREBASE');
  static Future<void> initialize() async {
    if (!enabled) return;
    // Uses native google-services.json / GoogleService-Info.plist configuration.
    await Firebase.initializeApp();
  }
}
