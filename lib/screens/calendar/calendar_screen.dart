import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:taskmap/screens/profile/profile_screen.dart';

import '../tasks/task_details_sheet.dart';

import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_header.dart';
import '../../widgets/white_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  static const String routeName = "/calendar";

  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Tasks due on a specific calendar day (year/month/day match on deadline).
  List<TaskModel> _tasksForDay(DateTime day, List<TaskModel> tasks) {
    return tasks.where((task) {
      return task.deadline.year == day.year &&
          task.deadline.month == day.month &&
          task.deadline.day == day.day;
    }).toList();
  }

  List<TaskModel> _tasksForMonth(DateTime month, List<TaskModel> tasks) {
    return tasks.where((task) {
      return task.deadline.year == month.year &&
          task.deadline.month == month.month;
    }).toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
    });
  }

  String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _selectedDayLabel(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                onProfilePressed: () {
                  Navigator.pushNamed(context, ProfileScreen.routeName);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: tasksAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text(
                      'Couldn\'t load tasks. Please try again.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  data: (tasks) => _buildCalendarBody(tasks),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(
        currentIndex: NavigationIndex.calendar,
      ),
    );
  }

  Widget _buildCalendarBody(List<TaskModel> tasks) {
    final monthTasks = _tasksForMonth(_focusedDay, tasks);
    final selectedTasks = _selectedDay == null
        ? <TaskModel>[]
        : _tasksForDay(_selectedDay!, tasks);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMonthHeader(monthTasks.length),
          const SizedBox(height: 8),
          WhiteCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: TableCalendar<TaskModel>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              currentDay: DateTime.now(),
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerVisible: false,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => _tasksForDay(day, tasks),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                weekendStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(color: AppColors.primaryBlue),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                markersAlignment: Alignment.bottomCenter,
                markerSize: 5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSelectedDaySection(selectedTasks),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(int deadlineCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _monthLabel(_focusedDay),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$deadlineCount deadline${deadlineCount == 1 ? '' : 's'} this month',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _buildSelectedDaySection(List<TaskModel> selectedTasks) {
    final label = _selectedDay == null ? '' : _selectedDayLabel(_selectedDay!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Deadlines for $label',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${selectedTasks.length} Task${selectedTasks.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (selectedTasks.isEmpty)
          _buildEmptyState()
        else
          ...selectedTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTaskCard(task),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return WhiteCard(
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 36,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          const Text(
            'No activities planned',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'You have no tasks due on this day.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (task.isDone)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: task.priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${task.priorityLabel} Priority',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 12),
              Text(
                'Due: ${_formatTime(task.deadline)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${(task.progress * 100).round()}% Done',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E9F2),
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showTaskDetailsSheet(context, task);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}
