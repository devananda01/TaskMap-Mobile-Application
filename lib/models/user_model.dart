import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;

  final bool emailVerified;

  final bool isPremium;
  final DateTime? premiumExpiry;
  final DateTime? premiumSince;

  final int aiUsageCount;
  final DateTime lastResetDate;

  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.emailVerified,
    required this.isPremium,
    this.premiumExpiry,
    this.premiumSince,
    required this.aiUsageCount,
    required this.lastResetDate,
    required this.createdAt,
  });

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    bool? emailVerified,
    bool? isPremium,
    DateTime? premiumExpiry,
    DateTime? premiumSince,
    int? aiUsageCount,
    DateTime? lastResetDate,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      premiumSince: premiumSince ?? this.premiumSince,
      aiUsageCount: aiUsageCount ?? this.aiUsageCount,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      emailVerified: data['emailVerified'] ?? false,
      isPremium: data['isPremium'] ?? false,
      premiumExpiry: data['premiumExpiry'] != null
          ? (data['premiumExpiry'] as Timestamp).toDate()
          : null,
      premiumSince: data['premiumSince'] != null
          ? (data['premiumSince'] as Timestamp).toDate()
          : null,
      aiUsageCount: data['aiUsageCount'] ?? 0,
      lastResetDate: (data['lastResetDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'emailVerified': emailVerified,
      'isPremium': isPremium,
      'premiumExpiry': premiumExpiry == null
          ? null
          : Timestamp.fromDate(premiumExpiry!),
      'premiumSince': premiumSince == null
          ? null
          : Timestamp.fromDate(premiumSince!),
      'aiUsageCount': aiUsageCount,
      'lastResetDate': Timestamp.fromDate(lastResetDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
