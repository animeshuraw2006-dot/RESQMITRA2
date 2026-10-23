# ResQMitra dependency fix

This ZIP updates `pubspec.yaml` to declare the packages named in the supplied `flutter analyze` report and changes the package name to `resq_mitra`, matching the `package:resq_mitra/...` imports shown in that report.

## Apply and test

1. Extract the ZIP.
2. Open the project root (the folder containing `pubspec.yaml`) in a terminal.
3. Run:

   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   ```

## Important limitation

The uploaded source ZIP contains only `lib/main.dart`, `pubspec.yaml`, `README.md`, and `assets/.gitkeep`. It does **not** contain the `lib/screens/`, `lib/services/`, `lib/splash_screen.dart`, or `test/widget_test.dart` files named in the analyzer report. Therefore this dependency update cannot repair source errors in those missing files. The reported `Future<void>` error in `lib/splash_screen.dart` must be fixed in the actual RESQMITRA2 project source. Also, Firebase and Supabase are both declared because the log shows imports from both; this does not migrate Firebase logic to Supabase or configure either backend.
