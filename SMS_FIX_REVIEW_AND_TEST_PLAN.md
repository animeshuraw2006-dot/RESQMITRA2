# RESQ-MITRA SMS fix review and device test plan

## Changes made in this revision

1. Kept one shared `AppState.createSos()` SMS dispatch path. Both the standard SOS confirmation flow and the High Alert 5-second countdown call this path, so they use the same contact list, permission check, message format, and per-contact loop.
2. Made missing emergency contacts explicit in the returned status, including a reminder to add contacts in Emergency Contacts.
3. Added validation for empty saved numbers and clearer per-contact failure reporting.
4. Improved the Android native SMS manager fallback for Android 12+ and validates phone numbers before asking Android to send them.
5. Preserved the distinction between an SMS request accepted by Android and actual delivery. The current native implementation does **not** receive carrier delivery receipts, so the UI must not claim the contact definitely received/read the SMS.
6. Changed a previously generic SMS exception message to show the actual platform exception in the app status so the next failure can be diagnosed.

## Important limitations

- This project revision has not been compiled with Flutter/Gradle in this environment. Source/ZIP checks are not a substitute for `flutter analyze`, `flutter build apk --debug`, or testing on the target phone.
- Android SMS delivery still depends on the user granting `SEND_SMS`, a valid contact number, an enabled SIM with outgoing SMS service, carrier coverage, and device/OS policy. Dual-SIM devices may need a default SMS SIM selected.
- Google Play restricts SMS permissions for many app categories. Confirm eligibility and distribution requirements before publishing.
- A successful `SmsManager` call means Android accepted the request, not that the carrier delivered it. This revision does not add delivery receipts.

## Required test procedure

1. Install the debug APK on a real Android phone with an active SIM and outgoing SMS service.
2. Open **Emergency Contacts**, add a second phone you control (with the recipient's consent), and verify the number including country code (India example: `+91XXXXXXXXXX`).
3. In **Permissions & safety**, tap SMS and grant the Android SMS permission before testing.
4. Confirm the phone can send a normal SMS from its Messages app.
5. Test standard SOS. Check the sender phone's SMS app/SIM behavior and the in-app status. Confirm the recipient receives the message.
6. Test High Alert SOS and let the 5-second countdown complete. Confirm the same.
7. Repeat with mobile data disabled but cellular signal present. SIM-based SMS should not require mobile data.
8. Test denied SMS permission, no saved contacts, malformed number, no SIM, and no cellular service. Verify the app reports failure instead of claiming delivery.
9. Run `flutter pub get`, `dart format lib`, `flutter analyze`, and `flutter build apk --debug` from the project root. Share the full first error if any command fails.

## Manual emergency fallback

Do not rely solely on this app for a real emergency until the device tests pass. In India, call 112 if immediate assistance is needed.
