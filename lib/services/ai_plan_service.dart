import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ai_plan_model.dart';

class AIPlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'aiPlans';

  Stream<List<AIPlanModel>> getPlans(String userId) {
    return _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final plans = snapshot.docs
              .map((doc) => AIPlanModel.fromFirestore(doc))
              .toList();

          plans.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

          return plans;
        });
  }

  Future<void> addPlan(AIPlanModel plan) async {
    await _db.collection(_collection).doc(plan.id).set(plan.toMap());
  }

  Future<void> updatePlan(AIPlanModel plan) async {
    await _db.collection(_collection).doc(plan.id).update(plan.toMap());
  }

  Future<void> deletePlan(String planId) async {
    await _db.collection(_collection).doc(planId).delete();
  }

  Future<void> addOrUpdatePlan(AIPlanModel plan) async {
    await _db
        .collection(_collection)
        .doc(plan.id)
        .set(plan.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteAllPlans(String userId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> savePlans(List<AIPlanModel> plans) async {
    final batch = _db.batch();

    for (final plan in plans) {
      final docRef = _db.collection(_collection).doc(plan.id);

      batch.set(docRef, plan.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }
}
