# RESQ-MITRA SOS push and siren setup

This project uses Supabase Auth + the `dispatch-sos` Edge Function + OneSignal. The OneSignal REST API key and Supabase service-role key must remain server-side.

## What the project changes

- Adds a yellow **SIREN** button immediately above Emergency Contacts. It plays `assets/high_alert_siren.ogg` in a loop and flashes the whole Home screen red/blue/white. Tap anywhere on the overlay to stop the sound and flashing.
- Adds an Android notification channel `resq_sos_alerts_v1` whose notification sound is the same siren clip. The dispatch function targets that channel. This lets Android play the channel sound when the app is backgrounded/closed, subject to Android notification permission/channel settings and device restrictions.
- In the foreground, the OneSignal notification listener plays the siren through Flutter audio and explicitly displays the notification.
- Adds server-only `notification_dispatch_logs` audit rows for no eligible responders, OneSignal errors, accepted sends and zero-recipient responses.
- The SOS is created through `dispatch-sos` / `dispatch_emergency`, with a server UUID and status. The function sends to OneSignal external IDs that correspond to verified/available responder Supabase user IDs.

## Required deployment steps

1. In Supabase SQL Editor, apply the updated `supabase/schema.sql` (or at minimum run its new `notification_dispatch_logs` table section). Review the full schema before applying it to a production database.
2. Ensure Edge Function secrets exist: `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY`. Never put `ONESIGNAL_REST_API_KEY` or the service-role key in Flutter, a build argument, or GitHub client-side variables.
3. Deploy the updated function from the project root: `supabase functions deploy dispatch-sos`.
4. In OneSignal, configure Android push using the Firebase Cloud Messaging credentials for the matching Android application ID (`com.example.resq_mitra`, unless changed in Gradle). This does not require Firebase Auth or Firestore; FCM is the Android transport.
5. Build with the actual public Supabase URL, public publishable key and OneSignal App ID, for example:

   ```powershell
   flutter pub get
   flutter build apk --debug --dart-define=SUPABASE_URL=https://tgyitcorasmzwnjganmj.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_PUBLISHABLE_KEY --dart-define=ONESIGNAL_APP_ID=YOUR_ONESIGNAL_APP_ID
   ```

6. Install the new APK on each test phone. Uninstall/reinstall if needed to recreate the Android notification channel after changing its sound. Grant notification permission and ensure the notification channel is not muted.
7. Each responder must sign in to the app so `OneSignal.login(supabaseUser.id)` associates the device's OneSignal external ID with the responder's Supabase Auth UUID. In `public.responder_profiles`, that same `user_id` must be `verified=true` and `available=true`. A responder row that is not verified/available will not be assigned.
8. Send a test SOS from a separate help-seeker account. Check the Edge Function logs and `public.notification_dispatch_logs`. A OneSignal API success with zero recipients means the responder device subscription/external ID/FCM configuration still needs fixing; it does not mean the phone received the notification.

## Delivery behavior and limitations

- `push_accepted` is not the same as a human responder acknowledging the emergency. The current function response reports OneSignal acceptance/recipient counts; verify actual delivery on devices and use the app's SOS acceptance flow separately.
- Android's notification-channel sound is played by the operating system as the notification sound. It is not a promise of indefinite siren playback when the app is closed. Foreground app notifications start the in-app looping siren. Background/closed-app continuous playback would require a carefully designed Android foreground-service/full-screen-notification implementation and must comply with Android and Play policies.
- This project currently assigns all verified and available responders, not only nearby responders. Add a trusted geospatial query before production deployment if radius-based dispatch is required.
- Push delivery depends on network, FCM/OneSignal configuration, permissions, device settings and power management. Keep emergency call fallback available; do not treat a push as guaranteed emergency-service dispatch.
