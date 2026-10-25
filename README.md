# ResQMitra – build on GitHub (no Flutter install needed)

1. Create a new **empty repository** on GitHub.
2. Unzip this package and upload **all files and folders** (including the hidden `.github` folder) to the repo root,
   or push them with git.
3. Open the repo → **Actions** tab → **Build ResQMitra** → it runs automatically on every push
   (or press **Run workflow**).
4. When the run turns green, open it and download **ResQMitra-apk** under *Artifacts*. Unzip it and install
   `app-release.apk` on your Android phone (allow "install unknown apps").
5. The optional **ResQMitra-web** artifact is a web build; it may fail because torch/SMS plugins are mobile-only –
   that does not affect the APK.

The workflow generates the `android/` folder itself and adds the permissions (see `scripts/patch_android.py`).
If a build fails, open the failed step and send me the red error text.

---

# ResQMitra – Flutter app

## 1. Create platform folders (once)
```
cd resqmitra
flutter create --org com.resqmitra --project-name resqmitra .
flutter pub get
```
(`flutter create .` adds the android/ and ios/ folders and keeps lib/, assets/ and pubspec.yaml.)

## 2. Android – android/app/src/main/AndroidManifest.xml
Inside `<manifest>` (above `<application>`) add:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FLASHLIGHT"/>
<queries>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
  <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
  <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="sms"/></intent>
</queries>
```
In android/app/build.gradle(.kts) set `minSdk = 23`.

## 3. iOS – ios/Runner/Info.plist
Add NSLocationWhenInUseUsageDescription, NSCameraUsageDescription, NSMicrophoneUsageDescription,
NSContactsUsageDescription, NSPhotoLibraryUsageDescription (and `LSApplicationQueriesSchemes`: tel, sms, https).
iOS cannot send SMS silently – it opens the Messages composer.

## 4. Run
`flutter run`

## Demo OTP
Mobile / email / contact "Verify" use the demo code **123456** until real OTP (Firebase Auth) is connected.

## Still to connect (backend)
`AlertService` in lib/services.dart is in-memory. To deliver SOS alerts to OTHER phones add Firebase
(Auth + Firestore + Cloud Messaging) inside `dispatch()`, `setStage()` and `cancel()`.

## Flutter Web image preview fix

Registration image/document previews use selected file bytes (`XFile.readAsBytes` and `Image.memory`) rather than `Image.file`/`FileImage`, which are unsupported on Flutter Web. The selected path is still retained for compatibility with the existing local form state. The responder dashboard displays photos only when the stored value is an HTTP(S) URL; local device paths are not portable across devices.


## Refinement update (this version)
* **SOS button** – bright red, heart-beat (lub-dub) pulse, 3 expanding signal rings and a breathing glow (`PulsingSosButton` in lib/widgets.dart).
* **Choose Your SOS / General / Women / Child** – rebuilt from your screenshots. The option artwork lives in `assets/ui/*.png`
  (cut from your images); card + arrow colours are in `lib/ui_meta.dart`.
* **Blood Needed** – new ICU screen (`lib/screens/blood_request.dart`) shown before the confirmation page.
  Answer NO → the ICU-only message. Answer YES → the full request form; the details travel with the SOS (SMS + responder screen).
* **Permissions** – each tile requests its real device permission when tapped and shows a live green tick;
  *Allow Permissions* walks through all of them one by one.
* **Instant intro** – the intro video plays on every launch. `main()` no longer awaits anything, and the first
  video frame is shown as a still while the video loads. To also remove the *native* white launch screen run once:
  `dart run flutter_native_splash:create` (config is at the bottom of pubspec.yaml).
* On Flutter **web** the intro plays muted (browsers block autoplay with sound).

## What's new (v2 UI)
- **Women SOS**: "Blood Needed" removed, **Missing / Lost** added (new artwork `assets/ui/w_missing.png`).
- **Floating PROFILE button** (bottom-right, every screen) → dark, professional Profile page: stats, My Badges,
  About Me, verification checklist + **COMPLETE PENDING VERIFICATION**, **SWITCH ROLE** (Help Seeker / Rescuer / Both).
- **Appreciation**: 15 badges (`assets/badges/`), only offered after the help seeker taps **I AM SAFE**.
  The responder gets a glowing spinning-badge reveal + splash; badges, ratings and reviews are stored in the Profile.
- **SOS pop-up** with looping siren for ONLINE responders on any screen; one tap → **Active Alert** screen (redesigned).
- Feedback tab removed from the responder dashboard. The optional Web build was removed from the GitHub workflow.

### Backend note
Everything is stored on the phone (SharedPreferences) and delivered through in-app streams
(`AlertService` in `lib/services.dart`). To reach OTHER phones, connect Firebase (Firestore + FCM) at:
`AlertService.dispatch` (SOS), `AlertService.sendAppreciation` (badge) and `AppState.receiveAppreciation` (profile).


## App icon (added)
The attached ResQ-Mitra logo is saved as `assets/icon/app_icon.jpg`. GitHub Actions runs `dart run flutter_launcher_icons` before building, so the Android launcher icon is generated for the APK.

## Neon backend starter (added)
See `backend/README.md`. Run `backend/sql/schema.sql` and `backend/sql/badges.sql` in Neon SQL Editor, then deploy the Node API from `backend/`. This is a secure-by-default scaffold requiring a real trusted authentication issuer before protected routes can be used. Current UI storage/alert streams are still local until explicitly wired to an authenticated API.
