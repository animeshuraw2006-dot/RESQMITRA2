# ResQMitra — Flutter Android starter

ResQMitra is a first-responder app prototype. This repository includes the supplied brand media and a GitHub Actions workflow for building a release APK.

## Assets included

```text
assets/
├── audio/
│   └── siren.ogg                 # supplied emergency siren
├── images/
│   └── resqmitra_logo.jpeg       # supplied ResQMitra logo
└── video/
    └── resqmitra_intro.mp4       # supplied intro video
```

All three supplied assets are declared in `pubspec.yaml` and referenced by `lib/main.dart`. Keep the paths and case exactly the same (GitHub builds on Linux, where paths are case-sensitive).

## Build on GitHub

1. Upload the **contents** of this folder to the root of your GitHub repository (so `pubspec.yaml`, `lib/`, `assets/`, `test/`, and `.github/` are at the repository root).
2. Commit and push to `main` or `master`, or run the workflow manually from the Actions tab.
3. Download the `ResQMitra-APK` artifact from the successful workflow run.

The workflow generates Android platform scaffolding if needed, installs dependencies, runs `flutter analyze`, runs widget tests, builds a release APK, and uploads it as an artifact.

## Local commands

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## What the prototype currently does

- Intro video and branded role selection
- Login and vertically arranged registration forms for Help Seeker, Rescuer, and Both
- Permission request screen
- SOS categories for General, Women, and Child emergencies
- High Alert five-second countdown with cancellation
- Emergency details and a Google Maps location link prepared for SMS confirmation
- Device flashlight toggle (supported devices only) and siren audio playback
- Emergency helpline list with phone-app launch
- Responder dashboard UI and appreciation/feedback UI

## Important limitations before real-world emergency use

This is a UI prototype, not a live dispatch system. Emergency SMS is prepared for the user to review and send; it is not silently delivered. Real responder matching, backend data storage, push notifications, authenticated accounts, live map tracking, actual voice recording/photo capture, and audited emergency delivery still need implementation and testing. Do not rely on this prototype as the only way to request emergency help. For an immediate emergency, use your local emergency number.

## Android permissions

Review the generated `android/app/src/main/AndroidManifest.xml` and add only the permissions required by features you actually enable. Test permission denial and devices without flash/location support. Do not request or use SMS/contacts permissions unnecessarily.


## Stage 1 backend integration foundation

Read [BACKEND_SETUP.md](BACKEND_SETUP.md) before enabling any live services. This project now includes Firebase Auth/Firestore/FCM service classes, Firestore rules, Cloud Functions alert fan-out, live GPS publishing, and encrypted local emergency-contact storage. Firebase remains disabled until you configure your own project. The existing responder map is still a placeholder; wire `google_maps_flutter` with a restricted API key and live data before treating it as a live map.
