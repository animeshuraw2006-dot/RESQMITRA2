# Fixes applied for GitHub Actions analysis errors

- Replaced `PermissionStatus.isGranted` / `isLimited` getters with enum comparisons to avoid getter compatibility errors.
- Declared `permission_handler` and `sqflite` dependencies in `pubspec.yaml`.
- Removed the unused `dart:convert` import from the registration wizard.
- Replaced deprecated `DropdownButtonFormField.value` with `initialValue` in registration and SOS screens.
- Captured the `ScaffoldMessengerState` before the async profile-clear operation and checked `mounted` before updating UI.
- Made permission information items const.

Run from the project root:

```bash
flutter pub get
 dart format lib test
flutter analyze
flutter test
flutter build apk --release
```

Note: GitHub Actions must run these commands in the folder containing this `pubspec.yaml`.
