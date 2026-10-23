# RESQ-MITRA — Flutter Android Starter

A structured Flutter project scaffold based on the RESQ-MITRA role-selection, unified registration, permission explainer, help-seeker, and responder screen designs.

## Included in this ZIP

- Role selection: Help Seeker, As Rescuer, Both
- Unified multi-step registration form with role-aware sections
- Contact, address, emergency contact, medical/accessibility, education, skills, availability and identity-document sections
- Permission explainer for location, notifications, calling, contacts, microphone and camera
- Demo home screens for help seekers and responders
- SOS request form and responder request list (demo/local flow)
- Local JSON profile persistence using SharedPreferences
- SQLite database service foundation
- Location, image picker, permission and dialler service foundations
- GitHub Actions workflow to build and upload an APK artifact
- Flutter widget test starter

## Important limitations

This is a development starter, not a certified or production-ready emergency service. The SOS and responder matching flows are demo/local UI flows until a trusted backend is configured. A local database cannot deliver requests to other devices.

Real SMS/email OTP, identity verification, push notifications, live responder matching, secure document upload, and admin approval require a configured backend/provider. Never use sample verification statuses as proof of identity. Do not store production secrets in the repository.

The app does not automatically grant all permissions. Android permissions are requested in context where implemented. Permission declarations and platform setup may need adjustment based on the final feature set and target Android SDK.

## Create Android platform files (if absent)

Install Flutter stable and Android SDK, then from the project root run:

```bash
flutter create . --platforms=android
flutter pub get
flutter analyze
flutter test
flutter run
```

If `android/` is already present, inspect it before running `flutter create`.

## Build APK locally

```bash
flutter pub get
flutter build apk --release
```

APK output:
`build/app/outputs/flutter-apk/app-release.apk`

## GitHub APK build

1. Upload/push the project to your repository's `main` branch.
2. Open **Actions** in GitHub.
3. Select **Build RESQ-MITRA Android APK**.
4. Choose **Run workflow** or push a commit.
5. When the workflow finishes, open the run and download the `RESQ-MITRA-Android-APK` artifact.

The workflow creates Android platform files if missing, installs dependencies, runs formatting/analyzer/tests, builds a release APK and uploads it.

## Suggested next production steps

1. Configure a real authentication provider and OTP verification.
2. Add a secure backend API and shared database.
3. Implement server-authoritative SOS lifecycle and responder assignment.
4. Configure push notifications and delivery monitoring.
5. Add privacy policy, consent flows, data retention and account deletion.
6. Test on physical Android devices, including denied permissions, no network, low battery and emergency scenarios.
7. Set up a protected release-signing process for distribution outside development/testing.

## Assets

Place the official RESQ-MITRA logo in `assets/images/resq_mitra_logo.png`. If no logo is supplied, the app uses a shield icon and text fallback.
