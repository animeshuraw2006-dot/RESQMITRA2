// Example only: use this pattern when all startup operations return Future<void>.
Future<void> runStartupTasks() async {
  await Future.wait<void>(<Future<void>>[
    initializeService(),
    loadPreferences(),
  ]);
}

Future<void> initializeService() async {}
Future<void> loadPreferences() async {}
