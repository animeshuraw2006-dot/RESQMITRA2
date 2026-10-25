import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nav.dart';
import 'root_overlay.dart';
import 'theme.dart';
import 'screens/splash.dart';

// No awaits before runApp → the intro screen appears with zero blank time.
// (AppState is initialised inside the splash screen, in parallel with the video.)
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ResQMitraApp());
}

class ResQMitraApp extends StatelessWidget {
  const ResQMitraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ResQMitra',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        navigatorKey: navKey,
        navigatorObservers: [AppNav.I],
        builder: (context, child) => RootOverlay(child: child ?? const SizedBox.shrink()),
        home: const SplashScreen(),
      );
}
