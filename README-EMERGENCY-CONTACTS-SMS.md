# RESQ-MITRA — Emergency Contacts and SOS SMS update

## Changes in this update
- Added a professional Emergency Contacts card on the home screen.
- Added an Emergency Contacts page with add (+), edit and remove actions.
- Contact fields: name, relation and phone number.
- Contacts are saved locally on the device using SharedPreferences.
- Added a full-name field during account creation and saves it as Supabase Auth `full_name` metadata.
- When standard SOS or High Alert SOS starts, the app attempts to send a formatted SMS to each saved contact with user name, SOS type, date/time, coordinates and a Google Maps link when a GPS fix is available.
- Added Android native SMS sending via `SmsManager`, including multipart message support.
- Added SMS permission to the permissions page and Android manifest.
- Retries once after a submission exception and displays the submission status.

## Important delivery limitations
SMS cannot be guaranteed to arrive immediately or at all. `SmsManager` returning successfully means Android accepted the send request; it does not prove carrier delivery or that the recipient read it. Delivery depends on SIM availability, the default SMS subscription, carrier/network coverage, account balance/plan and recipient network. A send exception can also be ambiguous, so retries may occasionally create duplicate messages. The app currently does not implement carrier delivery receipts or a durable SMS retry queue.

This automatic SMS implementation is Android-only. On web/desktop it will not send native SMS. Ensure the user grants SMS permission before an emergency and test with real devices/SIMs and consenting test recipients. For life-threatening emergencies in India, call 112 as well.

## Build
From the project folder:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter run` (Android device with SIM for SMS testing)

Build tools were not available in the editing environment, so this modified source has not been compiled or live-tested here. Review build output on your machine before relying on it in an emergency.

## October 2026 troubleshooting update
- Emergency contact entry now uses a dialog route instead of a modal bottom sheet to avoid the reported Flutter inherited-widget deactivation assertion during route teardown.
- The contact form validates local Indian 10-digit numbers (saved with `+91`) and explicit international numbers beginning with `+` (8–15 digits total).
- Android SMS permission is requested specifically for `SEND_SMS` through the native method channel, instead of the broad permission-handler SMS group. SOS SMS is still sent through the Android device's SIM and carrier.
- A call button remains next to every saved contact.

Important: this archive has not been compiled with Flutter or tested on a physical phone in this environment. Test SMS only with consenting test contacts, an active SIM, SMS service and permission. Android accepting an SMS request does not prove delivery. Supabase session restoration is used to skip login when a valid session exists; users must sign in again if the session expires or the app has no valid Supabase session.
