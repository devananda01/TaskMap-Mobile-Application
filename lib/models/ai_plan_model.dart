import 'package:cloud_firestore/cloud_firestore.dart';

class PlannedSession {
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool completed;

  const PlannedSession({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.completed = false,
  });

  PlannedSession copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? completed,
  }) {
    return PlannedSession(
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'completed': completed,
    };
  }

  factory PlannedSession.fromMap(Map<String, dynamic> map) {
    return PlannedSession(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      completed: map['completed'] ?? false,
    );
  }
}

class AIPlanModel {
  final String id;
  final String userId;
  final String taskId;
  final String taskTitle;
  final DateTime generatedAt;
  final List<PlannedSession> sessions;

  const AIPlanModel({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.taskTitle,
    required this.generatedAt,
    required this.sessions,
  });

  AIPlanModel copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? taskTitle,
    DateTime? generatedAt,
    List<PlannedSession>? sessions,
  }) {
    return AIPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      generatedAt: generatedAt ?? this.generatedAt,
      sessions: sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'sessions': sessions.map((e) => e.toMap()).toList(),
    };
  }

  factory AIPlanModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return AIPlanModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      taskId: data['taskId'] ?? '',
      taskTitle: data['taskTitle'] ?? '',
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      sessions: (data['sessions'] as List<dynamic>? ?? [])
          .map(
            (session) =>
                PlannedSession.fromMap(session as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
