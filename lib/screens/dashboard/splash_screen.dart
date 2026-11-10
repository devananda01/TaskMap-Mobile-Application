import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/biometric_provider.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/biometric_unlock_screen.dart';
import '../dashboard/dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const routeName = '/splash';

  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _resolveAndNavigate();
  }

  Future<void> _resolveAndNavigate() async {
    final user = await FirebaseAuth.instance.authStateChanges().first;

    if (!mounted) return;

    if (user == null) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      return;
    }

    // Valid session — check whether this user has biometrics enabled
    // before deciding whether to gate entry with an unlock prompt.
    final biometricState = ref.read(biometricProvider);
    await ref.read(biometricProvider.notifier).refresh();
    final refreshed = ref.read(biometricProvider);

    if (!mounted) return;

    final shouldGate = refreshed.available && refreshed.enabled;

    Navigator.of(context).pushReplacementNamed(
      shouldGate ? BiometricUnlockScreen.routeName : DashboardScreen.routeName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 96, height: 96),
              const SizedBox(height: 16),
              const Text(
                'TaskMap',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
