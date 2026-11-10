import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../utils/app_snackbar.dart';
import 'add_edit_task_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/section_label.dart';

//  It handles all the "slide up / drag down to close" behaviourn
void showTaskDetailsSheet(BuildContext context, TaskModel task) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TaskDetailsSheet(task: task),
  );
}

class TaskDetailsSheet extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskDetailsSheet({super.key, required this.task});

  @override
  ConsumerState<TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends ConsumerState<TaskDetailsSheet> {
  bool isAddingStep = false;

  final TextEditingController stepController = TextEditingController();

  @override
  void dispose() {
    stepController.dispose();
    super.dispose();
  }

  Future<void> _saveUpdatedSteps(
    TaskModel task,
    List<TaskStep> updatedSteps,
  ) async {
    final progress = ref
        .read(taskServiceProvider)
        .calculateProgress(updatedSteps);

    final updatedTask = task.copyWith(steps: updatedSteps, progress: progress);

    await ref.read(taskNotifierProvider.notifier).updateTask(updatedTask);
  }

  Future<void> _handleMenuSelection(String value) async {
    if (value == 'edit') {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddEditTaskScreen(existingTask: widget.task),
        ),
      );
    } else if (value == 'delete') {
      final deleted = await _showDeleteConfirmation(widget.task);

      if (deleted != true || !mounted) return;

      Navigator.pop(context);

      AppSnackbar.success(context, 'Task deleted successfully.');
    }
  }

  Future<bool?> _showDeleteConfirmation(TaskModel task) {
    bool isDeleting = false;
    String? errorText;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // avoid dismissing mid-delete
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Delete this task?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade600,
                        ),
                        children: [
                          const TextSpan(text: '"'),
                          TextSpan(
                            text: task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const TextSpan(
                            text:
                                '" will be permanently removed. This action cannot be undone.',
                          ),
                        ],
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isDeleting
                                ? null
                                : () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: const BorderSide(color: Color(0xFFE5E9F2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isDeleting
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isDeleting = true;
                                      errorText = null;
                                    });

                                    try {
                                      await ref
                                          .read(taskNotifierProvider.notifier)
                                          .deleteTask(task.id);

                                      if (!context.mounted) return;
                                      Navigator.pop(context, true);
                                    } catch (e) {
                                      setDialogState(() {
                                        isDeleting = false;
                                        errorText =
                                            'Unable to delete task. Please try again.';
                                      });
                                    }
                                  },
                            icon: isDeleting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.delete_outline, size: 18),
                            label: Text(isDeleting ? 'Deleting…' : 'Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (tasks) {
        final matchingTasks = tasks.where((t) => t.id == widget.task.id);

        if (matchingTasks.isEmpty) {
          return const SizedBox.shrink();
        }

        final task = matchingTasks.first;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController, // makes the drag handle work
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _buildDragHandle(),
                  const SizedBox(height: 12),
                  _buildTitleRow(task),
                  const SizedBox(height: 16),
                  _buildDeadlineAndPriority(task),
                  const SizedBox(height: 16),
                  _buildProgress(task),
                  const SizedBox(height: 20),
                  const SectionLabel('ASSIGNMENT NOTES'),
                  const SizedBox(height: 8),
                  _buildNotesBox(task),
                  const SizedBox(height: 20),
                  const SectionLabel('Study Breakdown', large: true),
                  const SizedBox(height: 10),
                  for (int i = 0; i < task.steps.length; i++)
                    _buildStepTile(task, i),
                  const SizedBox(height: 20),
                  _buildAddStepSection(task),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Small gray bar at the top, signals "drag me" to the user
  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // Module tag + title + 3-dot menu
  Widget _buildTitleRow(TaskModel task) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            task.module,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            task.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Task options',
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
                  SizedBox(width: 10),
                  Text('Edit Task'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Delete Task', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Two side-by-side boxes: Deadline and Priority
  Widget _buildDeadlineAndPriority(TaskModel task) {
    return Row(
      children: [
        Expanded(
          child: _infoBox(
            icon: Icons.calendar_today_outlined,
            label: 'Deadline',
            value: _formatDeadlineDate(task.deadline),
            subtitle: _formatDeadlineTime(task.deadline),
            valueColor: Colors.black,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _infoBox(
            icon: Icons.priority_high,
            label: 'Priority',
            value: task.priorityLabel,
            valueColor: task.priorityColor,
          ),
        ),
      ],
    );
  }

  // Formats a DateTime like "Friday, 5:00 PM"
  // Formats the date part, e.g. "Fri, 15 Aug 2026"
  String _formatDeadlineDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, ${date.day} $month ${date.year}';
  }

  // Formats the time part, e.g. "5:00 PM"
  String _formatDeadlineTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  // Progress label + bar
  Widget _buildProgress(TaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '${(task.progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: task.progress,
            minHeight: 7,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
          ),
        ),
      ],
    );
  }

  // Gray rounded box with the assignment notes text
  Widget _buildNotesBox(TaskModel task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Text(
        task.description.isNotEmpty
            ? task.description
            : 'No additional notes for this task.',
        style: const TextStyle(
          fontSize: 12.5,
          color: Color.fromARGB(255, 122, 117, 117),
          height: 1.4,
        ),
      ),
    );
  }

  // One row of the checklist: AppColors.green check circle + (strikethrough) text
  Widget _buildStepTile(TaskModel task, int index) {
    final step = task.steps[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: InkWell(
        onTap: () async {
          final updatedSteps = List<TaskStep>.from(task.steps);

          updatedSteps[index] = updatedSteps[index].copyWith(
            isDone: !updatedSteps[index].isDone,
          );

          await _saveUpdatedSteps(task, updatedSteps);
        },
        child: Row(
          children: [
            Icon(
              step.isDone ? Icons.check_circle : Icons.circle_outlined,
              color: step.isDone ? AppColors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  fontSize: 13,
                  color: step.isDone ? Colors.grey : Colors.black87,
                  decoration: step.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                stepController.text = step.title;

                final title = await showDialog<String>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Edit Step'),
                    content: TextField(
                      controller: stepController,
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, stepController.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );

                if (title == null || title.isEmpty) return;

                final updatedSteps = List<TaskStep>.from(task.steps);

                updatedSteps[index] = updatedSteps[index].copyWith(
                  title: title,
                );

                await _saveUpdatedSteps(task, updatedSteps);
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () async {
                final updatedSteps = List<TaskStep>.from(task.steps);

                updatedSteps.removeAt(index);

                await _saveUpdatedSteps(task, updatedSteps);
              },
            ),
          ],
        ),
      ),
    );
  }

  // "+ Add Steps"
  Widget _buildAddStepSection(TaskModel task) {
    if (!isAddingStep) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              isAddingStep = true;
              stepController.clear();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Step'),
        ),
      );
    }

    return Column(
      children: [
        TextField(
          controller: stepController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter study step...'),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () async {
                final title = stepController.text.trim();

                if (title.isEmpty) return;

                final updatedSteps = [
                  ...task.steps,
                  TaskStep(title: title, isDone: false),
                ];

                await _saveUpdatedSteps(task, updatedSteps);

                if (!mounted) return;

                setState(() {
                  isAddingStep = false;
                  stepController.clear();
                });
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ],
    );
  }
}
