import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';

/// Provides access to TaskService
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Streams all tasks from Firestore
final taskProvider = StreamProvider<List<TaskModel>>((ref) {
  return ref.watch(taskServiceProvider).getTasks();
});

/// Immutable key for the filtered-tasks family provider below. Two
/// instances with the same field values are treated as the same query by
/// Riverpod, so the stream isn't torn down and rebuilt on every rebuild.
class TaskFilterParams {
  final String? module;
  final List<TaskPriority> priorities;
  final bool sortDescending;

  const TaskFilterParams({
    this.module,
    this.priorities = const [],
    this.sortDescending = false,
  });

  @override
  bool operator ==(Object other) {
    if (other is! TaskFilterParams) return false;
    if (other.module != module) return false;
    if (other.sortDescending != sortDescending) return false;
    if (other.priorities.length != priorities.length) return false;
    for (final p in priorities) {
      if (!other.priorities.contains(p)) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(module, sortDescending, Object.hashAllUnordered(priorities));
}

/// Streams tasks matching the given module/priority/sort filters —
/// built server-side in TaskService.getFilteredTasks, not filtered in Dart.
final filteredTasksProvider =
    StreamProvider.family<List<TaskModel>, TaskFilterParams>((ref, params) {
      return ref
          .watch(taskServiceProvider)
          .getFilteredTasks(
            module: params.module,
            priorities: params.priorities,
            sortDescending: params.sortDescending,
          );
    });

/// Server-side count (Firestore aggregation query), keyed by isDone.
final taskCountProvider = FutureProvider.family<int, bool?>((ref, isDone) {
  return ref.watch(taskServiceProvider).getTaskCount(isDone: isDone);
});

/// Handles CRUD operations
class TaskNotifier extends Notifier<void> {
  late final TaskService _service;
  late final NotificationService _notificationService;

  @override
  void build() {
    _service = ref.read(taskServiceProvider);
    _notificationService = ref.read(notificationServiceProvider);
  }

  Future<void> addTask(TaskModel task) async {
    await _service.addTask(task);
    await _notificationService.scheduleTaskReminders(task);
    _refreshTaskCounts();
  }

  Future<void> updateTask(TaskModel task) async {
    await _service.updateTask(task);
    await _notificationService.scheduleTaskReminders(task);
    _refreshTaskCounts();
  }

  Future<void> deleteTask(String taskId) async {
    await _notificationService.cancelTaskReminders(taskId);
    await _service.deleteTask(taskId);
    _refreshTaskCounts();
  }

  void _refreshTaskCounts() {
    ref.invalidate(taskCountProvider(null));
    ref.invalidate(taskCountProvider(false));
    ref.invalidate(taskCountProvider(true));
  }
}

final taskNotifierProvider = NotifierProvider<TaskNotifier, void>(
  TaskNotifier.new,
);
