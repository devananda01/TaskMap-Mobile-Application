import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskmap/screens/profile/profile_screen.dart';
import '../../models/task_model.dart';
import 'package:taskmap/screens/tasks/task_details_sheet.dart';
import '../../widgets/app_header.dart';
import 'add_edit_task_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_navigation.dart';

import '../../providers/task_provider.dart';

class TaskManagementScreen extends ConsumerStatefulWidget {
  // Route name used with Navigator.pushNamed across the app
  static const String routeName = "/tasks";

  const TaskManagementScreen({super.key});

  @override
  ConsumerState<TaskManagementScreen> createState() =>
      _TaskManagementScreenState();
}

class _TaskManagementScreenState extends ConsumerState<TaskManagementScreen> {
  // Currently selected status chip (client-side — "Today"/"Upcoming" are
  // derived from DateTime.now(), so they aren't naturally a Firestore filter)
  String selectedFilter = 'Active';
  final List<String> filters = const [
    'Active',
    'Today',
    'Upcoming',
    'Completed',
    'All',
  ];

  // ── Advanced query filters (these go straight into the Firestore query
  // via filteredTasksProvider — see TaskService.getFilteredTasks) ─────────
  String? moduleFilter; // null = all modules
  final List<String> moduleOptions = const ['All', 'MBAP', 'AMDT', 'ECOMM'];

  final Set<TaskPriority> priorityFilter = {}; // empty = all priorities
  bool sortDescending = false;

  // Text controller for the search field
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ---------------- METHODS ----------------

  Future<void> toggleTaskDone(TaskModel task) async {
    final updatedTask = task.copyWith(isDone: !task.isDone);

    await ref.read(taskNotifierProvider.notifier).updateTask(updatedTask);
  }

  // Opens the Add Task form. If it returns a saved TaskModel, add it to null
  // the list (until Firestore + Riverpod streams the list automatically).
  Future<void> openAddTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
    );
  }

  Future<void> openEditTask(TaskModel task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditTaskScreen(existingTask: task)),
    );
  }

  void openTaskDetails(TaskModel task) {
    showTaskDetailsSheet(context, task);
  }

  void togglePriorityFilter(TaskPriority priority) {
    setState(() {
      if (priorityFilter.contains(priority)) {
        priorityFilter.remove(priority);
      } else {
        priorityFilter.add(priority);
      }
    });
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    final filterParams = TaskFilterParams(
      module: (moduleFilter == null || moduleFilter == 'All')
          ? null
          : moduleFilter,
      priorities: priorityFilter.toList(),
      sortDescending: sortDescending,
    );

    final tasksAsync = ref.watch(filteredTasksProvider(filterParams));
    final allTasksAsync = ref.watch(taskProvider);

    return tasksAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              // Composite Firestore queries (multiple where + orderBy)
              // need an index. On first run this error contains a direct
              // link to auto-create it in the Firebase console.
              'Unable to load tasks.\n${error.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ),

      data: (allTasks) {
        final now = DateTime.now();

        final filteredTasks = allTasks.where((task) {
          final matchesSearch = task.title.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );

          final matchesFilter = switch (selectedFilter) {
            'Active' => !task.isDone,
            'Completed' => task.isDone,
            'Today' =>
              task.deadline.year == now.year &&
                  task.deadline.month == now.month &&
                  task.deadline.day == now.day,
            'Upcoming' => task.deadline.isAfter(now) && !task.isDone,
            _ => true,
          };

          return matchesSearch && matchesFilter;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(
                    onProfilePressed: () {
                      Navigator.pushNamed(context, ProfileScreen.routeName);
                    },
                  ),

                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 14),
                  _buildFilterChips(),
                  const SizedBox(height: 10),
                  _buildModuleAndSortRow(allTasksAsync.value ?? const []),
                  const SizedBox(height: 10),
                  _buildPriorityChips(),
                  const SizedBox(height: 14),
                  Expanded(child: _buildTaskList(filteredTasks)),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primaryBlue,
            onPressed: openAddTask,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          bottomNavigationBar: const AppBottomNavigation(
            currentIndex: NavigationIndex.tasks,
          ),
        );
      },
    );
  }

  // ============================================================
  // Search bar
  // ============================================================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: const InputDecoration(
          hintText: 'Search your tasks...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ============================================================
  // Status chips row (Active / Today / Upcoming / Completed / All)
  // ============================================================
  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => setState(() => selectedFilter = filter),
            selectedColor: AppColors.primaryBlue,
            backgroundColor: const Color(0xFFE2E8F5),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // Module dropdown (single-field Firestore filter) + sort toggle
  // (Firestore orderBy)
  // ============================================================
  Widget _buildModuleAndSortRow(List<TaskModel> tasks) {
    final modules = <String>{};

    for (final task in tasks) {
      final module = task.module.trim();

      if (module.isNotEmpty && module != 'All') {
        modules.add(module);
      }
    }

    final moduleItems = ['All', ...modules.toList()..sort()];

    // Make sure the selected value always exists in the dropdown.
    final selectedModule =
        moduleFilter != null && moduleItems.contains(moduleFilter)
        ? moduleFilter
        : 'All';

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedModule,
                isExpanded: true,
                items: moduleItems.map((module) {
                  return DropdownMenuItem<String>(
                    value: module,
                    child: Text(
                      module == 'All' ? 'All Modules' : module,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    moduleFilter = value;
                  });
                },
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        InkWell(
          onTap: () {
            setState(() {
              sortDescending = !sortDescending;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 15,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Deadline',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Priority multi-select chips — multiple filter criteria on the
  // SAME field (priority), sent as a Firestore whereIn query.
  // ============================================================
  Widget _buildPriorityChips() {
    return Wrap(
      spacing: 8,
      children: TaskPriority.values.map((priority) {
        final isSelected = priorityFilter.contains(priority);
        final label = switch (priority) {
          TaskPriority.high => 'High',
          TaskPriority.medium => 'Medium',
          TaskPriority.low => 'Low',
        };
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => togglePriorityFilter(priority),
          selectedColor: AppColors.primaryBlue.withOpacity(0.15),
          checkmarkColor: AppColors.primaryBlue,
          backgroundColor: const Color(0xFFF8F9FC),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primaryBlue : Colors.black54,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryBlue
                  : const Color(0xFFE5E9F2),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // Task list (ListView.builder, scrollable)
  // ============================================================
  Widget _buildTaskList(List<TaskModel> filteredTasks) {
    final tasks = filteredTasks;

    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => _taskCard(tasks[index]),
    );
  }

  Widget _taskCard(TaskModel task) {
    final isOverdue = !task.isDone && task.deadline.isBefore(DateTime.now());
    final Color accentColor = isOverdue ? AppColors.red : task.priorityColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: isOverdue
            ? Border.all(color: AppColors.red.withOpacity(0.5), width: 1.4)
            : Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => openTaskDetails(task),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Checkbox to mark task as done
                  GestureDetector(
                    onTap: () => toggleTaskDone(task),
                    child: Icon(
                      task.isDone
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: task.isDone ? AppColors.primaryBlue : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.red,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 13,
                      color: isOverdue ? AppColors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDeadline(task.deadline),
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? AppColors.red : Colors.grey,
                        fontWeight: isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          '${(task.progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Formats a DateTime like "21 Thursday, 02:00 PM"
  String _formatDeadline(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final weekday = weekdays[date.weekday - 1];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} $weekday, ${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
