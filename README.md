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
