import 'dart:convert';


import 'package:http/http.dart' as http;

import '../models/ai_plan_model.dart';
import '../models/planner_preferences_model.dart';
import '../models/task_model.dart';

/// Generates a study plan by asking a real LLM (via Groq) to read the

class GroqAIPlanService {
 
  static const String _groqKey =
      GROQ_API_KEY;
  static const String _groqModel = 'llama-3.1-8b-instant';
  static const String _groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  DateTime _todayAt(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

 
  Future<List<AIPlanModel>> generatePlans({
    required List<TaskModel> tasks,
    required List<StudySlot> studySlots,
    required FocusPreference preference,
    required double confidence,
    required String notes,
    required String userId,
    required List<AIPlanModel> existingPlans,
  }) async {
    final incompleteTasks = tasks.where((t) => !t.isDone).toList();

    if (incompleteTasks.isEmpty || studySlots.isEmpty) {
      return [];
    }

    final prompt = _buildPrompt(
      tasks: incompleteTasks,
      studySlots: studySlots,
      preference: preference,
      confidence: confidence,
      notes: notes,
    );

    final aiReply = await _askGroq(prompt);

    return _turnReplyIntoPlans(
      aiReply: aiReply,
      tasks: incompleteTasks,
      userId: userId,
      existingPlans: existingPlans,
    );
  }

  Future<String> getStudyTip({required List<TaskModel> tasks}) async {
    final topTasks = tasks
        .take(3)
        .map((t) {
          return '${t.title} | '
              'Priority: ${t.priorityLabel} | '
              'Due: ${t.deadline} | '
              'Progress: ${(t.progress * 100).round()}%';
        })
        .join('\n');

    final prompt =
        '''
You are a study assistant inside TaskMap, a student task-management app.

Based on the student's current tasks below, give ONE practical study tip that is immediately useful.

Tasks:
$topTasks

Rules:
- Maximum 20 words.
- Make the advice specific to these tasks, not generic motivation.
- Prioritize the most urgent or important task when appropriate.
- Consider deadline, priority, and current progress.
- Give one clear action the student can take now.
- Do not mention that you are an AI.
- No quotes, markdown, bullet points,
-can have emojis.
- Return only the study tip.
''';

    final reply = await _askGroq(prompt);
    return reply.trim();
  }

  // ---------------- Prompt engineering ----------------

  String _buildPrompt({
    required List<TaskModel> tasks,
    required List<StudySlot> studySlots,
    required FocusPreference preference,
    required double confidence,
    required String notes,
  }) {
    final taskLines = tasks
        .map((t) {
          final daysLeft = t.deadline.difference(DateTime.now()).inDays;
          return '${t.id} | "${t.title}" | module: ${t.module} | '
              'priority: ${t.priority.name} | due in $daysLeft day(s) | '
              'estimated: ${t.estimatedDuration.inMinutes} min | '
              'progress: ${(t.progress * 100).round()}%';
        })
        .join('\n');

    final slotLines = studySlots
        .map((s) => '${s.start.format24h()} - ${s.end.format24h()}')
        .join('\n');

    final confidenceLabel = confidence < 0.3
        ? 'low (student needs longer, slower-paced sessions)'
        : confidence < 0.6
        ? 'medium'
        : 'high (student can use shorter, focused sessions)';

    return '''
You are a study-planning assistant inside a student productivity app called TaskMap.

STUDENT'S TASKS (not yet completed):
$taskLines

TODAY'S AVAILABLE STUDY WINDOWS:
$slotLines

FOCUS PREFERENCE: ${preference.label}
STUDENT'S SELF-RATED KNOWLEDGE CONFIDENCE: $confidenceLabel
ADDITIONAL INSTRUCTIONS FROM STUDENT: ${notes.trim().isEmpty ? 'None' : notes.trim()}

RULES:
1. Only schedule sessions inside the study windows above. Never overlap sessions, never go outside a window.
2. Only use task IDs exactly as given in the list above.
3. Prioritise tasks according to the focus preference:
   - "Balanced Schedule": mix tasks by urgency and priority.
   - "Prioritize Urgent Tasks": schedule the most urgent/high-priority tasks first, in order.
   - "Focus on One Subject": pick ONE module and only schedule tasks from that module.
   - "Light Revision Mode": prefer tasks that are already mostly complete, in shorter sessions.
4. Adjust session length for the estimated duration and the student's confidence — low confidence needs more time, high confidence needs less.
5. Give each session a short, specific "notes" field: a concrete tip for that session (e.g. "Review slides 3-5 and redo last week's practice questions"), not a generic sentence.
6. Follow the student's additional instructions above if any are given.
7. Session times must use 24-hour "HH:mm" format.

Respond with ONLY this JSON, no extra text, no markdown fences:
{
  "sessions": [
    { "taskId": "task ID here", "start": "HH:mm", "end": "HH:mm", "notes": "short specific tip" }
  ]
}
''';
  }

  // ---------------- Groq call ----------------

  Future<String> _askGroq(String prompt) async {
    final response = await http.post(
      Uri.parse(_groqUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqKey',
      },
      body: jsonEncode({
        'model': _groqModel,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.4,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Groq API error ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body);
    return json['choices'][0]['message']['content'] as String;
  }

  // ---------------- Reply parsing ----------------

  List<AIPlanModel> _turnReplyIntoPlans({
    required String aiReply,
    required List<TaskModel> tasks,
    required String userId,
    required List<AIPlanModel> existingPlans,
  }) {
    // LLMs sometimes wrap JSON in ```json fences even when asked not to.
    String cleanText = aiReply.trim();
    cleanText = cleanText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final data = jsonDecode(cleanText);
    final rawSessions = data['sessions'] as List;

    final tasksById = {for (final t in tasks) t.id: t};
    final existingByTask = {for (final p in existingPlans) p.taskId: p};

    final Map<String, List<PlannedSession>> sessionsByTask = {};

    for (final raw in rawSessions) {
      final taskId = raw['taskId'] as String?;
      final start = _parseHHmm(raw['start'] as String?);
      final end = _parseHHmm(raw['end'] as String?);
      final notes = (raw['notes'] as String?)?.trim();

      final task = taskId == null ? null : tasksById[taskId];

      // Skip (rather than crash on) any single malformed entry — a
      // partially valid plan is still useful, and one bad line from the
      // LLM shouldn't take down the whole feature.
      if (task == null || start == null || end == null || !end.isAfter(start)) {
        continue;
      }

      final description = (notes == null || notes.isEmpty)
          ? (task.description.isEmpty ? task.module : task.description)
          : notes;

      sessionsByTask
          .putIfAbsent(task.id, () => [])
          .add(
            PlannedSession(
              title: task.title,
              description: description,
              startTime: start,
              endTime: end,
            ),
          );
    }

    if (sessionsByTask.isEmpty) {
      throw Exception('AI reply had no valid, usable sessions.');
    }

    return sessionsByTask.entries.map((entry) {
      final task = tasksById[entry.key]!;
      final sessions = [...entry.value]
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      return AIPlanModel(
        id: existingByTask[task.id]?.id ?? 'plan_${task.id}',
        userId: userId,
        taskId: task.id,
        taskTitle: task.title,
        generatedAt: DateTime.now(),
        sessions: sessions,
      );
    }).toList();
  }

  DateTime? _parseHHmm(String? value) {
    if (value == null) return null;

    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;

    return _todayAt(hour, minute);
  }
}
