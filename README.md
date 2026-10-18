# RESQ-MITRA — Supabase integration starter

**NO LIFE LEFT BEHIND** · HELP | SUPPORT | TOGETHER

This update replaces Firebase Auth/Firestore client usage with Supabase Auth, a Supabase-backed SOS repository, database schema/RLS, Realtime responder assignments, and Edge Function endpoints for dispatch, cancellation, and acceptance. The existing branded UI, SOS categories, countdown flow, siren asset and intro video are retained.

## Configure Flutter

1. Use your selected RESQ-MITRA Supabase project `tgyitcorasmzwnjganmj` (Project URL: `https://tgyitcorasmzwnjganmj.supabase.co`) and open **Project Settings → API**. Copy the Project URL and the **publishable** client key (legacy `anon` key also works if your project still uses it).
2. In this folder run:

   ```bash
   flutter pub get
   flutter run --dart-define=SUPABASE_URL=https://tgyitcorasmzwnjganmj.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```

3. Configure email/password authentication in Supabase Auth. If email confirmation is enabled, a new user must confirm email and then log in.

## Configure the database and server functions

1. Run `supabase/schema.sql` in Supabase SQL Editor.
2. Install Supabase CLI, run `supabase login` and `supabase link --project-ref YOUR_PROJECT_REF`.
3. Set Edge Function secrets (never put service role keys in Flutter):

   ```bash
   supabase secrets set SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co SUPABASE_ANON_KEY=YOUR_ANON_KEY SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
   ```

4. Deploy functions:

   ```bash
   supabase functions deploy dispatch-sos
   supabase functions deploy cancel-sos
   supabase functions deploy accept-sos
   ```

5. The schema adds `responder_assignments` and `responder_locations` to `supabase_realtime` when the publication exists. If it does not, enable both in **Database → Publications** after the publication is created.
6. Have an administrator verify responder identities and set `responder_profiles.verified = true` and `available = true` for test responder accounts. Ordinary sign-up only creates citizen profiles.

## Important limitations before real deployment

- Dispatch currently assigns to all verified/available responders; it does **not** implement proximity ranking, FCM push delivery, or emergency-contact alerts. Realtime works while the responder app is connected; it is not a background push replacement.
- The Edge Function endpoints and SQL are integration scaffolding and require testing in your actual Supabase project. The acceptance endpoint should receive a final concurrency/security review before production; test simultaneous accepts and enforce a single winning responder in a single database transaction.
- No live emergency system can be guaranteed available. Test using dedicated test accounts/devices and keep India's official emergency number **112** accessible. Do not claim help has been contacted until a backend dispatch and responder acknowledgement are confirmed.
- OpenStreetMap tiles are integrated into the responder map. The Android application ID currently configured in Gradle is `com.example.resq_mitra`, and that exact value is used as the map package identifier. The map shows the responder GPS marker and the SOS coordinates from assigned requests.
- Responder last-known locations are stored in `responder_locations` only while a verified, available responder shares location. RLS permits a help-seeker to read a responder location only when that responder is assigned to the help-seeker’s active emergency. The Home screen now has an **OPEN EMERGENCY MAP** entry; it shows the help-seeker GPS marker and only those responder locations permitted by RLS for the user’s active emergency. The responder map shows the responder GPS marker and assigned SOS coordinates.
- Location sharing runs only while the responder map is open; Android background tracking is not enabled. The app stops its stream when the user taps Stop, but app termination can leave a last-known database row; clients must treat old `updated_at` values as stale.
- Proximity-based responder ranking, FCM delivery, audit logs, rate limits, expiry jobs, and retention policies are not included in this update.


## OpenStreetMap and location sharing

- `pubspec.yaml` already includes `flutter_map`, `latlong2`, and `geolocator`; `flutter pub get` resolves them.
- `android/app/src/main/AndroidManifest.xml` includes internet, coarse-location, and fine-location permissions. Location is requested at runtime.
- The responder map uses `https://tile.openstreetmap.org/{z}/{x}/{y}.png` and displays `© OpenStreetMap contributors`. Follow https://operations.osmfoundation.org/policies/tiles/; the public tile service has no uptime guarantee and must not be used for bulk/offline tile downloads.
- Run the updated `supabase/schema.sql` in Supabase SQL Editor to add the `responder_locations` table, RLS policies, and Realtime publication membership. Review this migration against any schema already applied in production before running it.
- A responder must be authenticated and have `responder_profiles.verified = true` and `available = true` to publish a location. Help-seekers can read only locations for responders assigned to their active SOS.
- This is foreground-only tracking. Do not assume it works when the app is minimized or terminated.
<<<<<<< HEAD


## Android push notification setup (OneSignal + FCM)

This project uses **Supabase** for authentication/database/server functions and **OneSignal** for push delivery. Firebase is used only as the Android Firebase Cloud Messaging (FCM) delivery provider; Firebase Authentication, Firestore, and Firebase Analytics are not required for this architecture. The OneSignal Flutter SDK is already listed in `pubspec.yaml`, and its initialization reads `ONESIGNAL_APP_ID` from a Dart define.

### 1. Register the Android package

The Android `applicationId` in `android/app/build.gradle.kts` is `com.example.resq_mitra`. Register an Android app with this exact package in Firebase Console, then download its `google-services.json`. If you later change `applicationId`, register the new package and download a matching JSON file.

### 2. Add the Firebase configuration file

Copy the downloaded file to exactly:

```text
android/app/google-services.json
```

Do not rename it to `google-services (1).json`, and do not use a JSON file registered for a different Android package. This ZIP intentionally does not contain a fabricated or account-specific `google-services.json`; you must download the real file from your Firebase project. Avoid committing credentials/configuration to public repositories; if your repository is public, consider supplying the file through a protected CI secret and writing it during the workflow.

### 3. Configure FCM in OneSignal

In OneSignal, open your app's Android push configuration and connect the Firebase/FCM credentials using the current OneSignal dashboard instructions. The Gradle plugin and JSON file alone do **not** create a OneSignal app or connect FCM credentials. Use the same Firebase project for the Android package and FCM credentials.

### 4. Build and initialize OneSignal

Run from the Flutter project root:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://tgyitcorasmzwnjganmj.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY --dart-define=ONESIGNAL_APP_ID=YOUR_ONESIGNAL_APP_ID
```

For a GitHub Actions build, provide `ONESIGNAL_APP_ID` as a repository variable and pass it as `--dart-define=ONESIGNAL_APP_ID=...`; also ensure the workflow has access to a real `android/app/google-services.json` before building. Never put a OneSignal REST API key, Supabase service-role key, or other server secret in Flutter code or Dart defines. Keep OneSignal REST API credentials in Supabase Edge Function secrets.

### 5. Firebase SDK dependency note

The Google Services Gradle plugin is configured at version `4.5.0` in the Android project and applied to the app module. This app does not add Firebase Analytics or the Firebase BoM because no Firebase client SDK product is used directly by the Flutter code; OneSignal handles its FCM integration. Add Firebase BoM/SDK dependencies only if you intentionally add a Firebase SDK that requires them.
=======
>>>>>>> bdc116573e8efccc6b50484739f8284efb896777

## Android build

```bash
flutter pub get
flutter build apk --debug --dart-define=SUPABASE_URL=https://tgyitcorasmzwnjganmj.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```


## Siren and emergency voice recordings

- The responder screen plays `assets/high_alert_siren.ogg` when a new assignment arrives while the screen is open. The responder can silence it. This is an in-app realtime listener, not a background push notification; configure and test FCM/APNs for alerts while the app is closed or suspended.
- The Emergency Confirmation page now supports microphone recording. After the SOS is confirmed, the recording is uploaded to the private `emergency-audio` Storage bucket and its metadata is saved in `emergency_audio_recordings`. Run the updated `supabase/schema.sql` in the selected project SQL Editor to create the table, private bucket, and RLS policies. Audio access is limited to the SOS requester and the responder who accepted it.
- After accepting an SOS, the responder can use the AUDIO action on that assignment to play the latest uploaded recording. If the recording is still uploading, try again shortly.
- **This is recorded audio uploaded after capture, not a continuous live microphone stream.** Supabase Database/Storage is not a low-latency media transport. True live two-way/one-way audio requires WebRTC with a media/signalling service (for example, a properly secured LiveKit deployment) and additional call lifecycle, permission, consent, and disconnect handling. Do not describe this current recording feature as live streaming.
- Test only with consenting test accounts/devices and sample incidents before any real deployment. Do not rely on the app as the only emergency channel; in India call **112** when immediate assistance is needed.

## Supabase configuration for GitHub Actions Android builds

In GitHub, open **Settings → Secrets and variables → Actions → Variables** and add these repository variables:

- `SUPABASE_URL` — the HTTPS URL of your Supabase project (for this project: `https://tgyitcorasmzwnjganmj.supabase.co`).
- `SUPABASE_PUBLISHABLE_KEY` — the project's publishable key from the Supabase API settings. Do not use a `service_role` or secret key in a mobile app.

The `.github/workflows/flutter.yml` workflow validates that both variables are present before building. If either is missing, the workflow stops with a clear error rather than creating an APK with empty compile-time values. After changing variables, trigger a new workflow run and install the newly generated artifact; an already-installed APK will not change.
