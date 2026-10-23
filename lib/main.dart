import 'package:flutter/material.dart';
import 'screens/role_selection_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ResqMitraApp());
}

class ResqMitraApp extends StatelessWidget {
  const ResqMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RESQ-MITRA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RoleSelectionScreen(),
    );
  }
}
