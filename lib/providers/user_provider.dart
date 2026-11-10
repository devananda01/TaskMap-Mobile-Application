import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

class UserNotifier extends Notifier<UserModel?> {
  late final UserService _userService;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  UserModel? build() {
    _userService = ref.read(userServiceProvider);

    loadUser();

    return null;
  }

  Future<void> loadUser() async {
    state = await _userService.getUser();
  }

  Future<void> increaseAiUsage() async {
    await _userService.increaseAiUsage();
    await loadUser();
  }

  Future<void> resetAiUsage() async {
    await _userService.resetAiUsage();
    await loadUser();
  }

  Future<void> upgradeToPro({DateTime? expiry}) async {
    await _userService.upgradeToPro(expiry: expiry);
    await loadUser();
  }

  Future<void> refreshUser() async {
    await loadUser();
  }

  Future<void> logout() async {
    await _firebaseService.logout();
    state = null;
  }
}

final userProvider = NotifierProvider<UserNotifier, UserModel?>(
  UserNotifier.new,
);
