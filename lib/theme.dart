import 'package:flutter/material.dart';

/// Colour tokens taken from the ResQMitra design PDF.
class C {
  static const navy = Color(0xFF0B1650);
  static const blue = Color(0xFF0A84FF);
  static const royal = Color(0xFF1F3FD6);
  static const seeker = Color(0xFF0A9DFF);
  static const rescuer = Color(0xFF00A81F);
  static const both = Color(0xFF00C9B7);
  static const sos = Color(0xFFFF0000);
  static const darkRed = Color(0xFF8B0000);
  static const cyan = Color(0xFF29C5F6);
  static const field = Color(0xFFF5F7FB);
  static const border = Color(0xFFD5DDF0);
  static const grey = Color(0xFF5B6478);
  static const ok = Color(0xFF1B9E4B);
  static const warn = Color(0xFFF59E0B);
}

ThemeData appTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: C.blue),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: C.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
            color: C.navy, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Roboto'),
      ),
    );

Route<T> fadeRoute<T>(Widget page, {int ms = 600}) => PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: ms),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    );
