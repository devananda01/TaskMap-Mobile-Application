import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/biometric_service.dart';
import 'firebase_provider.dart';
import '../services/firebase_service.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricState {
  final bool available;
  final bool enabled;
  final bool loading;

  const BiometricState({
    this.available = false,
    this.enabled = false,
    this.loading = false,
  });

  BiometricState copyWith({bool? available, bool? enabled, bool? loading}) {
    return BiometricState(
      available: available ?? this.available,
      enabled: enabled ?? this.enabled,
      loading: loading ?? this.loading,
    );
  }
}

final biometricProvider =
    StateNotifierProvider<BiometricController, BiometricState>((ref) {
      final service = ref.read(biometricServiceProvider);
      final firebaseService = ref.read(firebaseServiceProvider);
      return BiometricController(service, firebaseService);
    });

class BiometricController extends StateNotifier<BiometricState> {
  final BiometricService service;
  final FirebaseService firebaseService;

  BiometricController(this.service, this.firebaseService)
    : super(const BiometricState()) {
    refresh();
  }

  String? get _uid => firebaseService.getCurrentUser()?.uid;

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;

    state = state.copyWith(loading: true);
    final available = await service.isDeviceSupported();
    final enabled = await service.isEnabled(uid);
    state = state.copyWith(
      available: available,
      enabled: enabled,
      loading: false,
    );
  }

  /// Called from Profile screen's toggle. Requires a successful biometric
  /// check before turning it on.
  Future<bool> enable() async {
    final uid = _uid;
    if (uid == null) return false;

    final ok = await service.authenticate();
    if (ok) {
      await service.setEnabled(uid, true);
      state = state.copyWith(enabled: true);
    }
    return ok;
  }

  Future<void> disable() async {
    final uid = _uid;
    if (uid == null) return;

    await service.setEnabled(uid, false);
    state = state.copyWith(enabled: false);
  }

  /// Called from Login screen. Just runs the OS prompt.
  Future<bool> authenticate() => service.authenticate();
}
