import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String _collection = 'tasks';

  Stream<List<TaskModel>> getTasks() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return _db
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // Builds a single Firestore query from whichever filters are active.
  // module: single-field equality filter.
  // priorities: multiple values on the SAME field (priority) via whereIn.
  // isDone + module together demonstrate multiple filters on DIFFERENT
  // fields when both are supplied.
  // sortDescending: server-side sort via orderBy, not a Dart .sort().
  Stream<List<TaskModel>> getFilteredTasks({
    String? module,
    List<TaskPriority>? priorities,
    bool? isDone,
    bool sortDescending = false,
  }) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    Query<Map<String, dynamic>> query = _db
        .collection(_collection)
        .where('userId', isEqualTo: uid);

    if (module != null) {
      query = query.where('module', isEqualTo: module);
    }
    if (priorities != null && priorities.isNotEmpty) {
      query = query.where(
        'priority',
        whereIn: priorities.map((p) => p.index).toList(),
      );
    }
    if (isDone != null) {
      query = query.where('isDone', isEqualTo: isDone);
    }

    query = query.orderBy('deadline', descending: sortDescending);

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
    );
  }

  // Aggregation query — counts matching documents on the server instead of
  // fetching them all and calling .length in Dart.
  Future<int> getTaskCount({bool? isDone}) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    Query<Map<String, dynamic>> query = _db
        .collection(_collection)
        .where('userId', isEqualTo: uid);

    if (isDone != null) {
      query = query.where('isDone', isEqualTo: isDone);
    }

    final result = await query.count().get();
    return result.count ?? 0;
  }

  Future<void> addTask(TaskModel task) async {
    await _db.collection(_collection).doc(task.id).set(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await _db.collection(_collection).doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection(_collection).doc(taskId).delete();
  }

  double calculateProgress(List<TaskStep> steps) {
    if (steps.isEmpty) return 0;

    final completed = steps.where((step) => step.isDone).length;

    return completed / steps.length;
  }
}
