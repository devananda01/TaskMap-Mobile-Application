import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/white_card.dart';
import '../../widgets/section_label.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  static const String routeName = "/add-task";

  // Pass an existing TaskModel to edit it, or leave null to create a new one.
  final TaskModel? existingTask;

  const AddEditTaskScreen({super.key, this.existingTask});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  //texteditingcontroller - used because it allows us to control the text in the form and validate it
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customModuleController = TextEditingController();

  // Form state
  // Form state
  String? selectedModule;
  TaskType? selectedType;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late Duration selectedDuration;
  late TaskPriority selectedPriority;
  late bool reminderEnabled;

  final List<String> moduleOptions = ['MBAP', 'AMDT', 'ECOMM', 'Other...'];
  final List<Duration> durationOptions = const [
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 3),
  ];
  bool isCustomDuration = false;

  // True if we're editing an existing task instead of creating a new one
  bool get isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;

    // Pre-fill the form with the existing task's data,

    _titleController.text = task?.title ?? '';
    _descriptionController.text = task?.description ?? '';
    selectedModule = task == null
        ? null
        : (moduleOptions.contains(task.module) ? task.module : 'Other...');

    if (selectedModule == 'Other...') {
      _customModuleController.text = task?.module ?? '';
    }
    selectedType = task?.type;
    selectedDate =
        task?.deadline ?? DateTime.now().add(const Duration(days: 1));
    selectedTime = task != null
        ? TimeOfDay.fromDateTime(task.deadline)
        : const TimeOfDay(hour: 14, minute: 0);
    selectedDuration = task?.estimatedDuration ?? const Duration(hours: 2);
    isCustomDuration = !durationOptions.contains(selectedDuration);
    selectedPriority = task?.priority ?? TaskPriority.high;
    reminderEnabled = task?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customModuleController.dispose();
    super.dispose();
  }

  // ---------------- METHODS ----------------

  void goBack() {
    Navigator.pop(context);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> pickCustomDuration() async {
    // Simple custom duration picker using showDialog + a number field.
    final controller = TextEditingController(
      text: selectedDuration.inMinutes.toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom duration (minutes)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 90'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      setState(() {
        selectedDuration = Duration(minutes: result);
        isCustomDuration = true;
      });
    }
  }

  // Builds a TaskModel from the current form state and saves it.
  Future<void> saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedModule == null || selectedType == null) {
      AppSnackbar.error(context, 'Please select a module and type.');
      return;
    }
    final deadline = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final docRef = FirebaseFirestore.instance.collection('tasks').doc();
    final task = TaskModel(
      id: widget.existingTask?.id ?? docRef.id,
      userId: FirebaseAuth.instance.currentUser!.uid,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      module: selectedModule == 'Other...'
          ? _customModuleController.text.trim().toUpperCase()
          : selectedModule!,
      type: selectedType!,
      deadline: deadline,
      estimatedDuration: selectedDuration,
      priority: selectedPriority,
      reminderEnabled: reminderEnabled,
      progress: widget.existingTask?.progress ?? 0.0,
      isDone: widget.existingTask?.isDone ?? false,
      steps: widget.existingTask?.steps ?? const [],
    );

    try {
      final notifier = ref.read(taskNotifierProvider.notifier);

      if (isEditing) {
        await notifier.updateTask(task);
      } else {
        await notifier.addTask(task);
      }

      if (!mounted) return;

      AppSnackbar.success(
        context,
        isEditing ? 'Task updated successfully.' : 'Task added successfully.',
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.error(context, 'Unable to save task. Please try again.');
    }
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        foregroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goBack,
        ),
        // Title changes automatically based on whether we're editing
        title: Text(
          isEditing ? 'Edit Task' : 'Add Task',
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('TASK INFO', large: true),
                      const SizedBox(height: 12),
                      const SectionLabel('TASK TITLE'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration(
                          'e.g. NECT Network designing',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Please enter a task title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const SectionLabel('DESCRIPTION'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          'Additional details about the task...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownSection(
                              label: 'MODULE',
                              value: selectedModule,
                              items: moduleOptions,
                              onChanged: (value) =>
                                  setState(() => selectedModule = value!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTypeDropdown()),
                        ],
                      ),
                      if (selectedModule == 'Other...') ...[
                        const SizedBox(height: 16),

                        const SectionLabel('CUSTOM MODULE'),

                        const SizedBox(height: 6),

                        TextFormField(
                          controller: _customModuleController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _inputDecoration('Enter module name'),
                          validator: (value) {
                            if (selectedModule == 'Other...' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please enter a module name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('SCHEDULING', large: true),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildDatePicker()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTimePicker()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SectionLabel('DURATION ESTIMATE'),
                      const SizedBox(height: 8),
                      _buildDurationChips(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('PRIORITY LEVEL', large: true),
                      const SizedBox(height: 10),
                      _buildPriorityChips(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_none, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Enable Study Reminder',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: reminderEnabled,
                            activeColor: AppColors.primaryBlue,
                            onChanged: (value) =>
                                setState(() => reminderEnabled = value),
                          ),
                        ],
                      ),
                      if (reminderEnabled) ...[
                        const SizedBox(height: 6),
                        const Text(
                          "You'll receive reminders:",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ReminderBullet('2 days before'),
                              _ReminderBullet('1 day before'),
                              _ReminderBullet('6 hours before'),
                              _ReminderBullet('1 hour before'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saveTask,
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    // Button label also changes based on isEditing
                    label: Text(isEditing ? 'Update Task' : 'Save Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- SMALL BUILDER HELPERS ----------------

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: AppColors.textSecondaryOf(context),
      ),
      filled: true,
      fillColor: AppColors.inputFill(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.inputBorder(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.inputBorder(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildDropdownSection({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E9F2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isExpanded: true,
              hint: const Text('--- Select ---'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('--- Select ---'),
                ),
                ...items.map(
                  (item) => DropdownMenuItem(value: item, child: Text(item)),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('TYPE'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E9F2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TaskType?>(
              value: selectedType,
              isExpanded: true,
              hint: const Text('--- Select ---'),
              items: [
                const DropdownMenuItem<TaskType?>(
                  value: null,
                  child: Text('--- Select ---'),
                ),
                ...TaskType.values.map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(_typeLabel(type)),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => selectedType = value),
            ),
          ),
        ),
      ],
    );
  }

  String _typeLabel(TaskType type) {
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

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('DEADLINE DATE'),
        const SizedBox(height: 6),
        InkWell(
          onTap: pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E9F2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('TIME'),
        const SizedBox(height: 6),
        InkWell(
          onTap: pickTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E9F2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(
                  selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...durationOptions.map((duration) {
          final isSelected = !isCustomDuration && selectedDuration == duration;
          return _chip(
            label: '${duration.inHours} Hour${duration.inHours > 1 ? 's' : ''}',
            isSelected: isSelected,
            onTap: () => setState(() {
              selectedDuration = duration;
              isCustomDuration = false;
            }),
          );
        }),
        _chip(
          label: isCustomDuration
              ? '${selectedDuration.inMinutes} min'
              : 'Custom',
          isSelected: isCustomDuration,
          onTap: pickCustomDuration,
        ),
      ],
    );
  }

  Widget _buildPriorityChips() {
    return Row(
      children: TaskPriority.values.map((priority) {
        final isSelected = selectedPriority == priority;
        final color = TaskModel(
          id: '',
          userId: '',
          title: '',
          module: '',
          deadline: DateTime.now(),
          priority: priority,
        ).priorityColor;
        final label = TaskModel(
          id: '',
          userId: '',
          title: '',
          module: '',
          deadline: DateTime.now(),
          priority: priority,
        ).priorityLabel;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => selectedPriority = priority),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : AppColors.card(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE5E9F2),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : const Color(0xFFE5E9F2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _ReminderBullet extends StatelessWidget {
  final String label;

  const _ReminderBullet(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '•  $label',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
