# RESQ-MITRA — OneSignal Android setup

This update adds the Google Services Gradle plugin and the OneSignal Flutter SDK. It does not include your Firebase configuration or OneSignal app ID; those are project-specific and must be supplied by you.

## 1. Firebase Cloud Messaging configuration (Android push transport only)

1. In Firebase Console, create/select a Firebase project and add an Android app with the exact application ID from `android/app/build.gradle.kts`. This archive currently sets it to `com.example.resq_mitra`; if you change it, register that exact ID instead.
2. Download the matching `google-services.json`. Place it at `android/app/google-services.json` (inside the app module, not the repository root). Do not commit credentials or configuration files to a public repository.
3. In Firebase project settings, configure Cloud Messaging as required by OneSignal's current Android setup guide, then connect the FCM credentials to your OneSignal app.
4. In OneSignal, create/select the Android app and copy its **OneSignal App ID**.

Firebase Auth and Firestore are not used by this change. Firebase is used here only to configure Android push delivery for OneSignal. No Firebase Analytics dependency was added because it is not required for this purpose.

## 2. Build with OneSignal and Supabase values

Run from the Flutter project root:

```sh
flutter pub get
flutter build apk --debug \
  --dart-define=SUPABASE_URL="YOUR_SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="YOUR_SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=ONESIGNAL_APP_ID="YOUR_ONESIGNAL_APP_ID"
```

The app initializes the OneSignal SDK only when `ONESIGNAL_APP_ID` is provided. Initialization alone does not complete user-to-device registration or send SOS alerts. After Supabase login, call `OneSignal.login(supabase.auth.currentUser!.id)`; call `OneSignal.logout()` when the user signs out. Add this only after the app's authentication flow is confirmed.

## 3. Server-side dispatch

The OneSignal REST API key must remain on the server, such as a Supabase Edge Function secret. Never put the REST API key or Supabase `service_role` key in Flutter code, `--dart-define`, or the APK. The Edge Function should validate the signed-in user and SOS record, choose eligible responders, and send the notification using OneSignal's server API.

## 4. Important

- `google-services.json` is intentionally not included; it must be downloaded from your own Firebase project and must match the Android application ID.
- OneSignal push delivery is not guaranteed until the Firebase/OneSignal dashboards are configured and a real Android device is registered.
- Run `flutter pub get`, `flutter analyze`, and a debug APK build after adding your configuration. This archive was modified but has not been compiled or tested on a physical phone in this environment.


## 5. Required server secrets and deployment (push will not work without this)

In the linked Supabase project, set these secrets using your own values (do not put the REST API key in Flutter):

```sh
supabase secrets set ONESIGNAL_APP_ID=YOUR_ONESIGNAL_APP_ID ONESIGNAL_REST_API_KEY=YOUR_ONESIGNAL_REST_API_KEY
supabase functions deploy dispatch-sos
```

The existing Supabase server secrets `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` must also be set as described in `README.md`. In OneSignal, use the same app ID as the Flutter build. The REST API key is a private server secret.

## 6. Required responder setup

Each responder must log in to this same OneSignal app on a physical Android device, accept the notification permission prompt, and sign in to RESQ-MITRA. The app associates the OneSignal external ID with the signed-in Supabase Auth user UUID. An administrator must set that user's `responder_profiles.verified = true` and `available = true`. The dispatch function targets assigned responder UUIDs as OneSignal external IDs.

## 7. Build the APK with all three client values

```sh
flutter pub get
flutter build apk --debug --dart-define=SUPABASE_URL="YOUR_SUPABASE_URL" --dart-define=SUPABASE_PUBLISHABLE_KEY="YOUR_SUPABASE_PUBLISHABLE_KEY" --dart-define=ONESIGNAL_APP_ID="YOUR_ONESIGNAL_APP_ID"
```

Then install this newly built APK on both the requester and responder devices. Reinstalling an old APK will not include these changes.
