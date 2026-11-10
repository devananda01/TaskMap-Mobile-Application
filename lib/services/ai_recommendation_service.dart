import '../models/ai_plan_model.dart';
import '../models/planner_preferences_model.dart';
import '../models/task_model.dart';

class _RemainingTask {
  TaskModel task;
  Duration remainingDuration;

  _RemainingTask({required this.task, required this.remainingDuration});
}

class AIRecommendationService {
  DateTime _todayAt(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  double calculateTaskScore(TaskModel task) {
    double priorityScore;
    switch (task.priority) {
      case TaskPriority.high:
        priorityScore = 3;
        break;
      case TaskPriority.medium:
        priorityScore = 2;
        break;
      case TaskPriority.low:
        priorityScore = 1;
        break;
    }

    final workloadScore = (task.estimatedDuration.inMinutes / 60)
        .clamp(1, 5)
        .toDouble();

    final daysRemaining = task.deadline.difference(DateTime.now()).inDays;

    final urgencyScore = (14 - daysRemaining).clamp(1, 14).toDouble();

    final remainingWork = 1 - task.progress;

    return (priorityScore * 5) +
        (workloadScore * 4) +
        (urgencyScore * 6) +
        (remainingWork * 5);
  }

  List<TaskModel> rankTasks(List<TaskModel> tasks, FocusPreference preference) {
    final ranked = [...tasks];

    switch (preference) {
      case FocusPreference.balanced:
        ranked.sort(
          (a, b) => calculateTaskScore(b).compareTo(calculateTaskScore(a)),
        );
        break;

      case FocusPreference.urgentFirst:
        ranked.sort((a, b) {
          if (a.priority != b.priority) {
            return a.priority.index.compareTo(b.priority.index);
          }
          return a.deadline.compareTo(b.deadline);
        });
        break;

      case FocusPreference.oneSubject:
        ranked.sort(
          (a, b) => calculateTaskScore(b).compareTo(calculateTaskScore(a)),
        );
        if (ranked.isNotEmpty) {
          final module = ranked.first.module;
          ranked.removeWhere((t) => t.module != module);
        }
        break;

      case FocusPreference.lightRevision:
        ranked.sort((a, b) => b.progress.compareTo(a.progress));
        break;
    }

    return ranked;
  }

  Duration calculateSessionDuration(double confidence, TaskModel task) {
    final minutes = task.estimatedDuration.inMinutes;

    if (confidence < 0.3) {
      return Duration(minutes: (minutes * 1.2).round());
    }

    if (confidence < 0.6) {
      return Duration(minutes: minutes);
    }

    return Duration(minutes: (minutes * 0.8).round());
  }

  PlannedSession createSession({
    required TaskModel task,
    required DateTime startTime,
    required Duration duration,
  }) {
    final description = task.description.isEmpty
        ? task.module
        : task.description;

    return PlannedSession(
      title: task.title,
      description: description,
      startTime: startTime,
      endTime: startTime.add(duration),
    );
  }

  List<AIPlanModel> generatePlans({
    required List<TaskModel> tasks,
    required List<StudySlot> studySlots,
    required FocusPreference preference,
    required double confidence,
    required String userId,
    required List<AIPlanModel> existingPlans,
  }) {
    final rankedTasks = rankTasks(tasks, preference);
    final queue = rankedTasks.map((task) {
      return _RemainingTask(
        task: task,
        remainingDuration: calculateSessionDuration(confidence, task),
      );
    }).toList();
    // Sort study windows by start time
    studySlots.sort((a, b) {
      final aMinutes = a.start.hour * 60 + a.start.minute;
      final bMinutes = b.start.hour * 60 + b.start.minute;

      return aMinutes.compareTo(bMinutes);
    });

    final Map<String, AIPlanModel> generatedPlans = {};

    final existingByTask = {
      for (final plan in existingPlans) plan.taskId: plan,
    };

    for (final slot in studySlots) {
      DateTime currentTime = _todayAt(slot.start.hour, slot.start.minute);

      final sessionEnd = _todayAt(slot.end.hour, slot.end.minute);
      while (queue.isNotEmpty && currentTime.isBefore(sessionEnd)) {
        final currentTask = queue.first;
        final remainingWindow = sessionEnd.difference(currentTime);
        final studyDuration = currentTask.remainingDuration <= remainingWindow
            ? currentTask.remainingDuration
            : remainingWindow;
        final session = createSession(
          task: currentTask.task,
          startTime: currentTime,
          duration: studyDuration,
        );
        final existingPlan = generatedPlans[currentTask.task.id];

        if (existingPlan == null) {
          generatedPlans[currentTask.task.id] = AIPlanModel(
            id:
                existingByTask[currentTask.task.id]?.id ??
                'plan_${currentTask.task.id}',
            userId: userId,
            taskId: currentTask.task.id,
            taskTitle: currentTask.task.title,
            generatedAt: DateTime.now(),
            sessions: [session],
          );
        } else {
          generatedPlans[currentTask.task.id] = existingPlan.copyWith(
            sessions: [...existingPlan.sessions, session],
          );
        }
        currentTask.remainingDuration -= studyDuration;
        currentTime = session.endTime;
        Duration breakDuration = Duration.zero;

        if (studyDuration.inMinutes >= 120) {
          breakDuration = const Duration(minutes: 15);
        } else if (studyDuration.inMinutes >= 60) {
          breakDuration = const Duration(minutes: 10);
        }

        currentTime = currentTime.add(breakDuration);
        if (currentTask.remainingDuration <= Duration.zero) {
          queue.removeAt(0);
        }
      }
    }
    return generatedPlans.values.toList();
  }
}
