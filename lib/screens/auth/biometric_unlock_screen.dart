import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/biometric_provider.dart';
import '../../providers/firebase_provider.dart';
import '../../theme/app_colors.dart';
import 'login_screen.dart';
import '../dashboard/dashboard_screen.dart';

/// Shown instead of going straight to Dashboard when a valid Firebase
/// session exists AND the user has biometrics enabled. Acts as a local
/// unlock gate on top of the already-valid session — no Firebase call
/// happens here, only the OS fingerprint/face prompt.
class BiometricUnlockScreen extends ConsumerStatefulWidget {
  static const routeName = '/biometric-unlock';

  const BiometricUnlockScreen({super.key});

  @override
  ConsumerState<BiometricUnlockScreen> createState() =>
      _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends ConsumerState<BiometricUnlockScreen> {
  bool _failed = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptUnlock());
  }

  Future<void> _attemptUnlock() async {
    setState(() {
      _checking = true;
      _failed = false;
    });

    final ok = await ref.read(biometricProvider.notifier).authenticate();

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacementNamed(DashboardScreen.routeName);
    } else {
      setState(() {
        _checking = false;
        _failed = true;
      });
    }
  }

  Future<void> _useLoginInstead() async {
    await ref.read(firebaseServiceProvider).logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fingerprint_rounded,
                  size: 72,
                  color: _failed ? AppColors.red : AppColors.primaryBlue,
                ),
                const SizedBox(height: 20),
                Text(
                  _failed ? 'Authentication failed' : 'Unlock TaskMap',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _failed
                      ? 'Try again, or log in with your password instead.'
                      : 'Confirm your fingerprint or face to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 32),
                if (_checking)
                  const CircularProgressIndicator()
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _attemptUnlock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _useLoginInstead,
                    child: const Text('Use password instead'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
