# RESQ-MITRA changes in this package

## Included source changes
- Added a persisted role-selection page with Help Seeker, Rescuer, and Both modes.
- Enlarged the main SOS control and reduced it to a single large white `SOS` label.
- Moved the High Alert control before the normal SOS control and reduced its visual size.
- Added a flashlight toggle using `torch_light`.
- Updated the Supabase user trigger so every newly registered user receives a `responder_profiles` row. Existing users are backfilled by the SQL migration.
- Restored the OneSignal Android channel ID `resq_sos_alerts_v1` in `dispatch-sos`. `MainActivity.kt` creates this channel and configures `high_alert_siren.ogg`, vibration, and high importance.

## Required deployment steps
1. Run `supabase/migrations/20261021_auto_responder_profiles.sql` in the Supabase SQL Editor (or deploy it through your normal migration process).
2. Deploy the updated Edge Function: `supabase functions deploy dispatch-sos`.
3. Rebuild and reinstall the Android app. Android notification channel settings are persistent; if the channel already existed without sound, uninstall/reinstall the test app or reset that channel's notification settings before testing.
4. On Android, grant notification permission and ensure the device is not in silent/Do Not Disturb mode if you expect audible alerts.
5. Verify responders through your administrator workflow before setting `available=true`. The migration intentionally creates profiles with `verified=false` and `available=false`; auto-verifying every account would let arbitrary accounts receive/respond to emergency data and is unsafe.
6. Run `flutter pub get`, `dart format lib`, `flutter analyze`, and `flutter build apk --debug` on a machine with Flutter installed.

## Important limitations
- I could not run Flutter/Gradle builds in this environment because the Flutter and Dart SDKs are unavailable here.
- A notification channel can make the sound play when Android displays the push while the app is backgrounded/closed, but Android settings, permission state, OEM battery controls, and OneSignal device registration still affect delivery.
- Role choice is stored locally on this device. It does not itself grant verified responder status or change the Supabase authorization rules.
- The responder acceptance endpoint still depends on the deployed `accept-sos` Edge Function and the database `claim_emergency` RPC being deployed from the matching source/schema.
- GPS accuracy depends on device location settings, permission, network/GNSS conditions, and a fresh position. No code can guarantee a fixed accuracy in all environments.
