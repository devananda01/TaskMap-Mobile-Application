import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String _collection = 'users';

  /// Create a user document after successful registration
  Future<void> createUser(UserModel user) async {
    await _db.collection(_collection).doc(user.uid).set(user.toMap());
  }

  /// Load the currently logged in user
  Future<UserModel?> getUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) return null;

    final doc = await _db.collection(_collection).doc(firebaseUser.uid).get();

    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  /// Update user information
  Future<void> updateUser(UserModel user) async {
    await _db.collection(_collection).doc(user.uid).update(user.toMap());
  }

  /// Increase AI usage count
  Future<void> increaseAiUsage() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) return;

    await _db.collection(_collection).doc(firebaseUser.uid).update({
      'aiUsageCount': FieldValue.increment(1),
    });
  }

  /// Reset AI usage count
  Future<void> resetAiUsage() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) return;

    await _db.collection(_collection).doc(firebaseUser.uid).update({
      'aiUsageCount': 0,
      'lastResetDate': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Upgrade user to premium
  Future<void> upgradeToPro({DateTime? expiry}) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) return;

    await _db.collection(_collection).doc(firebaseUser.uid).update({
      'isPremium': true,
      'premiumExpiry': expiry == null ? null : Timestamp.fromDate(expiry),
      'premiumSince': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> ensureUserDocument(User firebaseUser) async {
    final docRef = _db.collection(_collection).doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) return;

    final newUser = UserModel(
      uid: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      emailVerified: firebaseUser.emailVerified,
      isPremium: false,
      premiumExpiry: null,
      premiumSince: null,
      aiUsageCount: 0,
      lastResetDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await docRef.set(newUser.toMap());
  }
}
