import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps device biometric auth (local_auth) and the small local preference
/// that remembers whether a given user enabled it. This is a LOCAL GATE
/// only — it never touches Firebase and never stores a password.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  static const _prefPrefix = 'biometric_enabled_';

  Future<bool> isDeviceSupported() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the OS fingerprint/face dialog. Returns true only on success.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to continue to TaskMap',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on Exception catch (e) {
      // Swallow known "not enrolled / not available / locked out" cases —
      // the provider decides what message to show.
      if (e.toString().contains(auth_error.notAvailable) ||
          e.toString().contains(auth_error.notEnrolled) ||
          e.toString().contains(auth_error.lockedOut) ||
          e.toString().contains(auth_error.permanentlyLockedOut)) {
        return false;
      }
      return false;
    }
  }

  /// Whether THIS uid has previously enabled biometric login.
  Future<bool> isEnabled(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefPrefix$uid') ?? false;
  }

  Future<void> setEnabled(String uid, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefPrefix$uid', enabled);
  }
}
