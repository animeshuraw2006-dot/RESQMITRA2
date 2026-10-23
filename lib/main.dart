import 'dart:async';

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ResQMitraApp());
}

class ResQMitraApp extends StatelessWidget {
  const ResQMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResQMitra',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xff159b95),
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const JoinPage()),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'ResQMitra',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Color(0xff123b58),
          ),
        ),
      ),
    );
  }
}

enum UserRole { seeker, rescuer, both }

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  UserRole? selectedRole;

  void continueToSignup() {
    final role = selectedRole;
    if (role == null) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => SignupPage(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LogoWidget(),
              const SizedBox(height: 14),
              const Text(
                'Join ResQMitra',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff123b58),
                ),
              ),
              const Text(
                'Choose how you want to use ResQMitra.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RoleCard(
                      icon: Icons.shield_outlined,
                      title: 'Help Seeker',
                      subtitle: 'Need Assistance',
                      selected: selectedRole == UserRole.seeker,
                      onTap: () => setState(
                        () => selectedRole = UserRole.seeker,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RoleCard(
                      icon: Icons.person,
                      title: 'Volunteer as Rescuer',
                      subtitle: 'Help Others',
                      selected: selectedRole == UserRole.rescuer,
                      onTap: () => setState(
                        () => selectedRole = UserRole.rescuer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RoleCard(
                icon: Icons.volunteer_activism_outlined,
                title: 'Help Seeker and Rescuer',
                subtitle: 'Together, We Save Lives.',
                wide: true,
                selected: selectedRole == UserRole.both,
                onTap: () => setState(() => selectedRole = UserRole.both),
              ),
              const SizedBox(height: 14),
              const Text(
                'BECOME A FORCE FOR CHANGE.\nUNITE. RESPOND. PROTECT.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xff123b58),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: selectedRole == null ? null : continueToSignup,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff2998df),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool wide;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: wide ? 124 : 154,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xffe4fbfa)
              : const Color(0xfff7fcfd),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? const Color(0xff079d98)
                : const Color(0xffa9d1d7),
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? const Color(0xff079d98)
                    : const Color(0xff218da2),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: wide ? 42 : 47,
                    color: wide
                        ? const Color(0xff078e8a)
                        : title.contains('Rescuer')
                            ? const Color(0xff55a84c)
                            : const Color(0xff1483bf),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: wide ? 16 : 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff123b58),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: wide ? 15 : 12,
                      fontWeight: wide ? FontWeight.bold : FontWeight.normal,
                      color: wide
                          ? const Color(0xff087e79)
                          : const Color(0xff263238),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  final UserRole role;

  const SignupPage({super.key, required this.role});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();

  String get roleName {
    switch (widget.role) {
      case UserRole.seeker:
        return 'Help Seeker';
      case UserRole.rescuer:
        return 'Volunteer as Rescuer';
      case UserRole.both:
        return 'Help Seeker and Rescuer';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _createAccount() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form validated. Account creation still requires a configured authentication provider.'),
      ),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign up as $roleName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff123b58),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your full name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email or phone number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your email or phone number'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _createAccount,
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xff169d92), width: 3),
      ),
      child: const Icon(
        Icons.volunteer_activism,
        color: Color(0xff123b58),
        size: 48,
      ),
    );
  }
}
