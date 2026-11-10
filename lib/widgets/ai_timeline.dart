import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planner_preferences_model.dart';

import '../models/ai_plan_model.dart';
import '../theme/app_colors.dart';

enum _SessionUiStatus { completed, upNext, pending }

extension _SessionUiStatusX on _SessionUiStatus {
  Color get color {
    switch (this) {
      case _SessionUiStatus.completed:
        return AppColors.green;
      case _SessionUiStatus.upNext:
        return AppColors.primaryBlue;
      case _SessionUiStatus.pending:
        return Colors.grey;
    }
  }

  String get label {
    switch (this) {
      case _SessionUiStatus.completed:
        return 'COMPLETED';
      case _SessionUiStatus.upNext:
        return 'UP NEXT';
      case _SessionUiStatus.pending:
        return 'PENDING';
    }
  }
}

// Figures out the status of session `index` given the full session list:
// the first not-yet-completed session is "up next", the rest are "pending".
_SessionUiStatus _statusFor(List<PlannedSession> sessions, int index) {
  final session = sessions[index];
  if (session.completed) return _SessionUiStatus.completed;

  final firstPendingIndex = sessions.indexWhere((s) => !s.completed);
  if (firstPendingIndex == index) return _SessionUiStatus.upNext;

  return _SessionUiStatus.pending;
}

class AITimeline extends ConsumerWidget {
  final List<AIPlanModel> aiPlans;
  final bool allowMarkComplete;
  final bool scrollable;
  final double? maxHeight;
  final Function(AIPlanModel plan, int sessionIndex)? onToggleComplete;

  const AITimeline({
    super.key,
    required this.aiPlans,
    this.allowMarkComplete = true,
    this.scrollable = false,
    this.maxHeight,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Flatten every session from every plan

    final timelineItems = <Map<String, dynamic>>[];

    for (final plan in aiPlans) {
      for (final session in plan.sessions) {
        timelineItems.add({'plan': plan, 'session': session});
      }
    }

    // Sort chronologically
    timelineItems.sort(
      (a, b) => (a['session'] as PlannedSession).startTime.compareTo(
        (b['session'] as PlannedSession).startTime,
      ),
    );

    Widget timeline = Column(
      children: [
        for (int i = 0; i < timelineItems.length; i++) ...[
          _sessionRow(
            timelineItems[i]['plan'] as AIPlanModel,
            [timelineItems[i]['session'] as PlannedSession],
            0,
            isLast: false,
          ),

          if (i < timelineItems.length - 1)
            () {
              final current = timelineItems[i]['session'] as PlannedSession;

              final next = timelineItems[i + 1]['session'] as PlannedSession;

              final gap = next.startTime.difference(current.endTime);

              if (gap.inMinutes < 10) {
                return const SizedBox.shrink();
              }

              return _buildBreakRow(gap);
            }(),
        ],
      ],
    );
    for (final item in timelineItems) {
      final session = item['session'] as PlannedSession;
    }

    if (!scrollable) {
      return timeline;
    }

    return SizedBox(
      height: maxHeight ?? 280,
      child: SingleChildScrollView(child: timeline),
    );
  }

  Widget _sessionRow(
    AIPlanModel plan,
    List<PlannedSession> sessions,
    int index, {
    required bool isLast,
  }) {
    final s = sessions[index];
    final status = _statusFor(sessions, index);
    final color = status.color;

    final start = TimeOfDay.fromDateTime(s.startTime);
    final end = TimeOfDay.fromDateTime(s.endTime);
    final durationMinutes = s.endTime.difference(s.startTime).inMinutes;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // dot + vertical line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFE5E9F2)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // session card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: color, width: 3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // time row
                  Row(
                    children: [
                      Text(
                        '${start.format24h()} – ${end.format24h()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _smallTag(
                        '$durationMinutes MINS',
                        Colors.grey.shade200,
                        Colors.black54,
                      ),
                    ],
                  ),
                  // status badge
                  if (status.label.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _smallTag(status.label, color.withOpacity(0.12), color),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  // mark-complete toggle (replaces the old per-step checklist,
                  // since PlannedSession only stores a single `completed` flag)
                  const SizedBox(height: 10),
                  if (allowMarkComplete)
                    _completeToggle(plan, index, s.completed),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completeToggle(AIPlanModel plan, int sessionIdx, bool completed) {
    return InkWell(
      onTap: () {
        if (onToggleComplete != null) {
          onToggleComplete!(plan, sessionIdx);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: completed ? AppColors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              completed ? 'Marked complete' : 'Mark as complete',
              style: TextStyle(
                fontSize: 12.5,
                color: completed ? Colors.grey : Colors.black87,
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallTag(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildBreakRow(Duration gap) {
    String title;
    IconData icon;
    Color color;

    if (gap.inMinutes >= 90) {
      title = 'Free Time';
      icon = Icons.weekend;
      color = Colors.orange;
    } else if (gap.inMinutes >= 30) {
      title = 'Meal Break';
      icon = Icons.restaurant;
      color = Colors.deepOrange;
    } else if (gap.inMinutes == 15) {
      title = '15min-Short Break';
      icon = Icons.coffee;
      color = const Color.fromARGB(255, 255, 7, 7);
    } else if (gap.inMinutes == 10) {
      title = '10min-Short Break';
      icon = Icons.coffee;
      color = const Color.fromARGB(255, 200, 74, 6);
    } else {
      title = 'Transition';
      icon = Icons.arrow_downward;
      color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 26, bottom: 14, top: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  '$title • ${gap.inMinutes} mins',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
