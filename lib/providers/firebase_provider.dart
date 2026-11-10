import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
