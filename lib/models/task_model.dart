import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { high, medium, low }

enum TaskType { assignment, exam, reading, project, other }

// One step inside a task's "Study Breakdown" checklist
class TaskStep {
  final String title;
  final bool isDone;

  const TaskStep({required this.title, this.isDone = false});

  TaskStep copyWith({String? title, bool? isDone}) {
    return TaskStep(title: title ?? this.title, isDone: isDone ?? this.isDone);
  }

  factory TaskStep.fromMap(Map<String, dynamic> map) {
    return TaskStep(
      title: map['title'] as String,
      isDone: map['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {'title': title, 'isDone': isDone};
}

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String module; // e.g. "MBAP", "AMDT", "ECOMM"
  final TaskType type;
  final DateTime deadline; // combined date + time
  final Duration estimatedDuration;
  final TaskPriority priority;
  final bool reminderEnabled;
  final double progress; // 0.0 - 1.0
  final bool isDone;
  final List<TaskStep> steps;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.module,
    this.type = TaskType.assignment,
    required this.deadline,
    this.estimatedDuration = const Duration(hours: 1),
    this.priority = TaskPriority.medium,
    this.reminderEnabled = true,
    this.progress = 0.0,
    this.isDone = false,
    this.steps = const [],
  });

  // Creates a copy of this task with some fields replaced. Handy when
  // editing an existing task in the Add/Edit form.
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? module,
    TaskType? type,
    DateTime? deadline,
    Duration? estimatedDuration,
    TaskPriority? priority,
    bool? reminderEnabled,
    double? progress,
    bool? isDone,
    List<TaskStep>? steps,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      module: module ?? this.module,
      type: type ?? this.type,
      deadline: deadline ?? this.deadline,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      priority: priority ?? this.priority,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      progress: progress ?? this.progress,
      isDone: isDone ?? this.isDone,
      steps: steps ?? this.steps,
    );
  }

  // ---------------- DISPLAY HELPERS ----------------
  // Small helpers used by the UI so screens don't repeat formatting logic.

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFD64545);
      case TaskPriority.medium:
        return const Color(0xFFD9822B);
      case TaskPriority.low:
        return const Color(0xFF1E9E4D);
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String get typeLabel {
    switch (type) {
      case TaskType.assignment:
        return 'Assignment';
      case TaskType.exam:
        return 'Exam';
      case TaskType.reading:
        return 'Reading';
      case TaskType.project:
        return 'Project';
      case TaskType.other:
        return 'Other';
    }
  }

  factory TaskModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return TaskModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      module: data['module'] ?? '',
      type: TaskType.values[data['type'] ?? 0],
      deadline: (data['deadline'] as Timestamp).toDate(),
      estimatedDuration: Duration(minutes: data['estimatedMinutes'] ?? 60),
      priority: TaskPriority.values[data['priority'] ?? 1],
      reminderEnabled: data['reminderEnabled'] ?? true,
      progress: (data['progress'] ?? 0).toDouble(),
      isDone: data['isDone'] ?? false,
      steps: (data['steps'] as List<dynamic>? ?? [])
          .map((step) => TaskStep.fromMap(step as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'module': module,
      'type': type.index,
      'deadline': deadline,
      'estimatedMinutes': estimatedDuration.inMinutes,
      'priority': priority.index,
      'reminderEnabled': reminderEnabled,
      'progress': progress,
      'isDone': isDone,
      'steps': steps.map((s) => s.toMap()).toList(),
    };
  }
}

// ---------------- FAKE DATA ----------------
// Sample tasks used until Firestore is connected. Import this list from
// any screen that needs dummy data, e.g.:
/*  import 'task_model.dart' show fakeTasks;
final List<TaskModel> fakeTasks = [
  TaskModel(
    id: 'task_1',
    title: 'ECOMM Presentation',
    description:
        'Finalize slides and rehearse the presentation flow with the team.',
    module: 'ECOMM',
    type: TaskType.project,
    deadline: DateTime(2026, 7, 2, 14, 0), // Thursday 2:00 PM
    estimatedDuration: const Duration(hours: 2),
    progress: 0.5,
    priority: TaskPriority.medium,
    steps: const [
      TaskStep(title: 'Finalize slide deck', isDone: true),
      TaskStep(title: 'Rehearse with team', isDone: false),
    ],
  ),
  TaskModel(
    id: 'task_2',
    title: 'MBAP Proposal',
    description:
        'Review specification and finalize CRUD planning for the upcoming '
        'project submission. Ensure there is an appropriate AI feature and '
        'multiple advance additional features.',
    module: 'MBAP',
    type: TaskType.assignment,
    deadline: DateTime(2026, 7, 3, 17, 0), // Friday 5:00 PM
    estimatedDuration: const Duration(hours: 2),
    priority: TaskPriority.high,
    progress: 0.75,
    steps: const [
      TaskStep(title: 'Review lecture slides', isDone: true),
      TaskStep(title: 'Design wireframe', isDone: true),
      TaskStep(title: 'Prepare CRUD explanation', isDone: true),
      TaskStep(title: 'Finalize Figma pages', isDone: false),
    ],
  ),
  TaskModel(
    id: 'task_3',
    title: 'AMDT Proposal',
    description: 'Do the part 3 persona research and write-up.',
    module: 'AMDT',
    type: TaskType.assignment,
    deadline: DateTime(2026, 7, 6, 9, 0), // Monday 9:00 AM
    estimatedDuration: const Duration(hours: 1),
    priority: TaskPriority.low,
    progress: 0.50,
    steps: const [
      TaskStep(title: 'Research target persona', isDone: true),
      TaskStep(title: 'Write persona document', isDone: false),
    ],
  ),
];
*/
