# ResQMitra Stage 1 — Firebase backend and live responder foundation

This stage adds a Firebase-ready service layer, Firestore security rules, FCM token registration, secure local emergency-contact storage, GPS publishing, SOS record creation, and Cloud Functions for alert fan-out. It is **not production-ready dispatch** until you configure your own Firebase project, test on physical devices, and complete the safety checklist below.

## 1. Create and configure Firebase

1. Create a project in the Firebase Console. Add an Android app using the exact `applicationId` in `android/app/build.gradle` (or `build.gradle.kts`).
2. Enable **Email/Password** under Authentication → Sign-in method.
3. Create a Cloud Firestore database.
4. Install FlutterFire CLI and run from the Flutter project root:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   This creates `lib/firebase_options.dart`. If you want to use the native configuration path in this starter, place the downloaded `google-services.json` in `android/app/` and configure the Google Services Gradle plugin per Firebase's current Android instructions. Do not commit service-account private keys.
5. Add Firebase initialization to `main.dart` **after** configuring FlutterFire. For the provided gated bootstrap, import `services/firebase_bootstrap.dart` and call `await FirebaseBootstrap.initialize()` before `runApp`; make `main` async and use `WidgetsFlutterBinding.ensureInitialized()` first. Build with `--dart-define=RESQMIRA_FIREBASE=true` only after native Firebase configuration is complete. Until then, leave the flag false.

## 2. Add Android configuration

- Ensure `android/app/src/main/AndroidManifest.xml` has only needed permissions: `INTERNET`, coarse/fine location, notifications (Android 13+), camera and microphone only if those features are enabled.
- For Google Maps, obtain an Android Maps SDK key, restrict it to your app's package and signing certificate, and add it as a manifest `com.google.android.geo.API_KEY` value via a local secret/Gradle property. Do not put an unrestricted key in source control.
- Use a valid `google-services.json` for Firebase Messaging. Test notification permission and background behavior on real Android versions.

## 3. Deploy Firestore rules and Cloud Functions

Install Firebase CLI, sign in, copy `.firebaserc.example` to `.firebaserc` and replace the project ID. Then:

```bash
firebase login
firebase use YOUR_FIREBASE_PROJECT_ID
firebase deploy --only firestore:rules
cd functions
npm ci   # first run may require npm install if no package-lock.json is present
npm run build
cd ..
firebase deploy --only functions
```

Cloud Functions deployment may require the Blaze billing plan. Review costs before enabling it. Function alert fan-out sends data-only FCM notifications to online responders. Add Android notification-channel and foreground/background handling in the client before relying on audible siren alerts.

## 4. Service APIs added

- `AuthService`: email/password registration and sign-in; writes minimal profile fields.
- `EmergencyService.createSos`: authenticated SOS document with coordinates, status, server timestamps, and a 1,000-character description limit.
- `EmergencyService.watchOpenEmergencies`: real-time open emergency stream.
- `EmergencyService.setResponderOnline`: publishes availability and optional current location/token.
- `EmergencyService.acceptEmergency`: claims an emergency (server rules should be hardened against race conditions before launch).
- `LocationService` and `LiveLocationPublisher`: permission-aware GPS lookup and opt-in location stream.
- `NotificationService`: requests notification permission and stores the user's current FCM token.
- `SecureContactsService`: stores emergency contact names/numbers locally in Android encrypted secure storage; contact numbers are not uploaded by this service.

## 5. Security and life-safety checklist — required before public release

- Harden responder authorization using verified server-side role claims; do not trust a user-editable profile role. The provided rules are a starter and must be security-reviewed.
- Implement atomic/transactional emergency acceptance so two responders cannot both claim the same incident.
- Filter alert fan-out by distance and emergency category; currently it fans out to online responder tokens (up to 500) and is not geofenced.
- Add rate limiting, abuse prevention, App Check, token cleanup, delivery monitoring, audit retention policy, account deletion and privacy policy.
- Encrypt and minimize sensitive fields; define retention/deletion for location traces. Only collect live location while the user explicitly enables a response or emergency session.
- Implement client handling for FCM in foreground/background/terminated states and a notification channel. Do not assume data-only FCM always produces a visible or audible notification.
- Add map markers for help seeker and responder and show location freshness/accuracy. Maps need a restricted API key and billing setup.
- Confirm the user sees a clear consent state before sharing coordinates or contacting emergency contacts. Do not silently SMS/call contacts.
- Test on real devices with denied permissions, poor network, duplicate taps, stale GPS, app killed, low battery and no responders available.
- Keep a fallback to call India's emergency number 112; never advertise this prototype as guaranteed emergency dispatch.

## Current status

This commit is an integration foundation. It adds the services/rules/functions but does not automatically provision Firebase, register the app in your Firebase project, place API keys, or make the existing UI screens call every service. Those steps require your Firebase project settings and explicit configuration. Until completed, keep Firebase disabled and the app in prototype mode.
