/// Backend address. Set at build time:
///   flutter build apk --release --dart-define=API_BASE=https://your-api.onrender.com
/// Leave it empty and the app runs in local-only mode (nothing is sent to a server).
const String kApiBase = String.fromEnvironment('API_BASE', defaultValue: '');
bool get kBackendOn => kApiBase.isNotEmpty;
