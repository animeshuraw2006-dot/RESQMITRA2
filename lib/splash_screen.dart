import 'dart:async';
import 'package:flutter/material.dart';

/// ResQMitra animated splash screen.
///
/// Connect [checkAuthentication] to your existing authentication system and
/// [destinationBuilder] to your existing login/home screens.
class SplashScreen extends StatefulWidget {
  final Future<bool> Function() checkAuthentication;
  final Widget Function(bool isLoggedIn) destinationBuilder;

  const SplashScreen({
    super.key,
    required this.checkAuthentication,
    required this.destinationBuilder,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _taglineController;
  bool _navigationStarted = false;

  @override
  void initState() {
    super.initState();

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _openNextScreen();
  }

  Future<void> _openNextScreen() async {
    bool isLoggedIn = false;

    // Keep the splash visible for at least 3 seconds, while checking session.
    try {
      // Start the session check immediately, while keeping the splash visible
      // for at least three seconds. Awaiting the operations separately avoids
      // mixing Future<void> and Future<bool> in a Future.wait<Object> list.
      final authenticationCheck = widget.checkAuthentication();
      await Future<void>.delayed(const Duration(seconds: 3));
      isLoggedIn = await authenticationCheck;
    } catch (_) {
      // If the session check fails, send the user to login.
      isLoggedIn = false;
    }

    if (!mounted || _navigationStarted) return;
    _navigationStarted = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => widget.destinationBuilder(isLoggedIn),
      ),
    );
  }

  @override
  void dispose() {
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07152D),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF102B50),
              Color(0xFF07152D),
              Color(0xFF030916),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoSize =
                  (constraints.maxHeight * 0.24).clamp(120.0, 190.0);

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle blue glow behind the logo.
                  Container(
                    width: logoSize + 80,
                    height: logoSize + 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF168BFF).withValues(alpha: 0.20),
                          blurRadius: 70,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                  ),

                  // Logo, app name, and moving tagline.
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/resqmitra_logo.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Temporary fallback until the original logo is added.
                          return Icon(
                            Icons.health_and_safety_rounded,
                            size: logoSize * 0.78,
                            color: Colors.white,
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'ResQMitra',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 30,
                        width: double.infinity,
                        child: ClipRect(
                          child: LayoutBuilder(
                            builder: (context, box) {
                              const textWidth = 340.0;
                              final distance = box.maxWidth + textWidth;

                              return AnimatedBuilder(
                                animation: _taglineController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      box.maxWidth -
                                          (_taglineController.value * distance),
                                      0,
                                    ),
                                    child: child,
                                  );
                                },
                                child: const SizedBox(
                                  width: textWidth,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'HELP | PROTECT | SUPPORT | TOGETHER',
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Color(0xFF8FD2FF),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Loading animation near the bottom.
                  const Positioned(
                    bottom: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF4D5A),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Preparing your safety network...',
                          style: TextStyle(
                            color: Color(0xFF9FB3CE),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
