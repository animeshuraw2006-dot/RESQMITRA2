# ResQMitra Flutter build-error fix kit

IMPORTANT: This is a workflow and repair guide, not the full corrected app source. The uploaded ZIP contained only `.github/workflows/build-apk.yml`; it did not contain `pubspec.yaml` or the Dart files listed in the analyzer output. Therefore the complete app cannot be patched or verified until the actual Flutter project ZIP is provided.

## 1. Add missing packages

Open the app's `pubspec.yaml`. Under the existing `dependencies:` section add these entries (do not duplicate entries already present; keep `flutter: sdk: flutter` and all existing dependencies):

```yaml
google_maps_flutter: ^2.12.3
supabase_flutter: ^2.9.1
```

Then run from the directory containing `pubspec.yaml`:

```bash
flutter pub get
flutter analyze
```

## 2. Fix `lib/splash_screen.dart` line 45

Error: `The element type 'Future<void>' can't be assigned to the list type 'Future<Object>'`.

Inspect the `Future.wait` call and the list around line 45. If every operation in that list returns `Future<void>`, use `Future.wait<void>([ ... ])` instead of `Future.wait<Object>([ ... ])`, or remove the explicit `<Object>` type so Dart can infer the type. If the list intentionally mixes return types, adjust the list to a consistent type based on the actual operations. Do not apply this blindly without checking the list contents.

## 3. `victim_screen.dart` deprecation

The `value` deprecation at line 74 is an info-level warning, not one of the compilation errors. For a `DropdownButtonFormField`, change `value:` to `initialValue:` if it represents the initial selection. If the selection must update dynamically, manage it using the appropriate state/controller pattern for that field.

## 4. Google Maps and Supabase setup

Adding packages resolves the missing Dart library symbols only when imports and code are valid. A Google Maps API key/platform setup is separately required to display Google Maps. Supabase must be initialized with the project's URL and anon/publishable key before calls using `Supabase.instance.client`.

## 5. Replace the workflow

Copy this kit's `.github/workflows/build-apk.yml` into the repository at the same path. This workflow searches for `pubspec.yaml` in the repository, runs `flutter pub get`, `flutter analyze`, and `flutter build apk --release`, then uploads the APK as a workflow artifact. It cannot compensate for missing Flutter source files or unresolved Dart errors.

## 6. To produce a fully corrected source ZIP

Upload the actual Flutter project ZIP containing `pubspec.yaml`, `lib/main.dart`, and the relevant `lib/screens/` and `lib/services/` files. The workflow-only ZIP is not enough to modify the app code safely.
