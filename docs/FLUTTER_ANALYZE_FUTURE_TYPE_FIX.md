# Flutter analyzer fix: `Future<void>` vs `Future<Object>`

The reported diagnostic is:

```text
The element type 'Future<void>' can't be assigned to the list type 'Future<Object>'
lib/splash_screen.dart:45:9
```

This happens when a list or `Future.wait` call is typed as `Future<Object>` while one of its entries returns `Future<void>`. The uploaded project archive does not contain `lib/splash_screen.dart`; its splash screen is the `SplashPage` class inside `lib/main.dart`, and there is no `Future.wait` call in that file. Therefore this diagnostic cannot be reproduced against this archive's current source.

## Correct fix when all operations return `Future<void>`

Change a call such as:

```dart
await Future.wait<Object>([
  initializeService(), // Future<void>
  loadPreferences(),    // Future<void>
]);
```

to:

```dart
await Future.wait<void>([
  initializeService(),
  loadPreferences(),
]);
```

Or, if the futures are intentionally stored in a list, type the list to match:

```dart
final List<Future<void>> startupTasks = [
  initializeService(),
  loadPreferences(),
];
await Future.wait<void>(startupTasks);
```

Do not use `Future.wait<void>` if any operation is expected to return a value that the caller needs. In that case, use a common result type or await the `Future<void>` operation separately.

## Verification note

This archive was checked for ZIP integrity. Flutter/Dart analysis could not be run in this environment, and the original `lib/splash_screen.dart` diagnostic cannot be confirmed without the exact file from the `RESQMITRA2` folder that produced it.
