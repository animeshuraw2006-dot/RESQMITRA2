# ResQMitra Flutter starter

Flutter/Dart UI prototype for ResQMitra. Includes the supplied intro video, siren audio, and logo assets, plus a GitHub Actions workflow that generates Android platform scaffolding if needed, runs analysis, builds a release APK, and uploads it as an artifact.

## Run locally

1. Install Flutter stable and Android Studio.
2. From this directory run:

   ```bash
   flutter create --platforms=android --project-name=resqmitra .
   flutter pub get
   flutter analyze
   flutter run
   ```

## Build on GitHub

Commit the project files, including `.github/workflows/build-apk.yml`, to your repository's `master` or `main` branch. Open **Actions**, select **Build ResQMitra APK**, and download the `ResQMitra-APK` artifact from a successful run.

## Screens included in this prototype

- Intro video and role selection
- Login and vertically arranged Help Seeker / Rescuer / Both registration forms with a final submit button
- Permission explanation and request screen
- Home dashboard with SOS, High Alert, flashlight, siren, online/offline toggle, responders and helplines
- General SOS, Women SOS and Child SOS categories
- Emergency confirmation form with description, location lookup, SMS composer option, voice/photo UI toggles and Do Not Call checkbox
- Five-second High Alert countdown and cancel action
- Responder dashboard/map placeholder, appreciation and badge selection

## Important limitations

This is an initial UI prototype, not a production-ready emergency dispatch service and not a pixel-perfect reproduction of every PDF screen. The current responder map is a placeholder; live responder matching, push notifications, backend persistence, real-time maps, voice recording and camera capture/upload need implementation. SMS opens the messaging app for user confirmation; the app does not silently send SMS. The app must be tested on real Android devices, and platform permissions and emergency numbers must be verified before release.

## Android permissions and release

Review `android/app/src/main/AndroidManifest.xml` after scaffolding. Request only permissions justified by implemented features. Background location and automatic SMS sending have additional platform and Play policy restrictions. Configure signing credentials securely through GitHub Secrets before publishing a store-ready release.


## GitHub Actions APK build troubleshooting

The Flutter project root must be the repository root: `pubspec.yaml`, `lib/`, `test/`, `assets/`, and `.github/` should be directly inside the repository, not nested one extra level inside `resqmitra_flutter/`. The workflow checks for `android/app/build.gradle` (or `build.gradle.kts`) and generates Android platform files if they are missing. After extracting this ZIP, upload the *contents* of `resqmitra_flutter/` to the repository root.
