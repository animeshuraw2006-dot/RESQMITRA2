# ResQMitra Flutter starter

A Flutter UI starter based on the supplied 15-page ResQMitra design PDF. Includes the intro video and siren/logo assets supplied with the request.

## Run

1. Install Flutter stable and Android Studio / Xcode as appropriate.
2. Create platform folders if needed: `flutter create .` (run inside this directory).
3. Run `flutter pub get`.
4. Run on a physical device: `flutter run`.

## Current screens

- 6–8 second intro video with skip/continue
- Role selection, login, and vertically scrolling registration forms for Help Seeker, Rescuer, and Both
- Permission request screen
- Home dashboard with SOS categories, High Alert, flashlight, siren, online/offline state, responders and helplines
- General / Women / Child SOS categories and confirm-emergency form
- Five-second High Alert countdown with cancel button
- Responder dashboard/map placeholder and appreciation/badge screen
- Emergency helpline dial links

## Important integration notes

This is a UI prototype, not yet a production emergency dispatch system. SMS links open the phone's messaging app for user confirmation; the app does not silently send SMS. Live responder matching, push notifications, backend storage, and real-time maps need a backend and a Maps SDK/API key. Voice recording and camera controls are represented in the confirmation UI and need capture/upload implementation. Verify emergency numbers and permission policies for the launch region before release.

### Android permissions

When platform folders are generated, review `android/app/src/main/AndroidManifest.xml` and add only the permissions needed for your release, such as `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, `CAMERA`, `RECORD_AUDIO`, `POST_NOTIFICATIONS`, and `CALL_PHONE` (only if directly placing calls). Background location, SMS permissions, and automatic SMS sending have additional Play policy and runtime restrictions; do not request them unless justified and approved.

### Before launch

- Add a secure API/backend for accounts, verified contacts, responder availability, SOS creation and status updates.
- Implement authenticated push notifications and server-side responder matching.
- Integrate Google Maps or another map provider and handle location permission denial gracefully.
- Test High Alert cancellation, duplicate prevention, network failure, battery saver, and device-specific flashlight/audio behavior.
- Add privacy policy, consent, data retention rules, and a clearly tested emergency escalation flow.
