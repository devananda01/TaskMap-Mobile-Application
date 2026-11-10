import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskmap/models/task_model.dart';
import 'package:taskmap/models/ai_plan_model.dart';

import 'package:taskmap/providers/user_provider.dart';
import 'package:taskmap/providers/ai_plan_provider.dart';
import 'package:taskmap/providers/task_provider.dart';
import 'package:taskmap/screens/planner/Ai_planner_screen.dart';

import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/white_card.dart';
import '../../widgets/ai_timeline.dart';
import '../../widgets/app_header.dart';
import '../../theme/app_colors.dart';
import '../../services/notification_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  static const String routeName = "/dashboard";

  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // ---------------- COLORS ----------------

  bool isLoading = false;

  // ---------------- METHODS ----------------

  void openProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void openPlanner() {
    Navigator.pushNamed(context, '/planner');
  }

  void openTasks() {
    Navigator.pushNamed(context, '/tasks');
  }

  void openAddTask() {
    Navigator.pushNamed(context, '/add-task');
  }

  void generateAiPlan() {
    Navigator.pushNamed(context, '/planner');
  }

  // ---------------- BUILD ----------------
  // No AppBar — the logo + greeting live directly in the body, like Figma.
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskProvider);
    final aiPlansAsync = ref.watch(aiPlanProvider);

    return tasksAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (error, stack) =>
          Scaffold(body: Center(child: Text(error.toString()))),

      data: (tasks) {
        final upNextTasks = tasks.where((t) => !t.isDone).toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));

        final todaysTasks = tasks.where((task) {
          final now = DateTime.now();

          return task.deadline.year == now.year &&
              task.deadline.month == now.month &&
              task.deadline.day == now.day;
        }).toList()..sort((a, b) => a.deadline.compareTo(b.deadline));

        final completedTasks = tasks.where((t) => t.isDone).length;

        final totalTasks = tasks.length;

        final upcomingTasks = tasks
            .where((t) => !t.isDone && t.deadline.isAfter(DateTime.now()))
            .length;

        final weeklyProgress = totalTasks == 0
            ? 0.0
            : completedTasks / totalTasks;
        final aiPlans = aiPlansAsync.value ?? [];
        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeader(onProfilePressed: openProfile),
                    const SizedBox(height: 16),
                    _buildGreetingCard(),
                    const SizedBox(height: 16),
                    _buildStatsStrip(),
                    const SizedBox(height: 16),
                    _buildWeeklyProgress(
                      weeklyProgress: weeklyProgress,
                      completedTasks: completedTasks,
                      todaysTasks: todaysTasks.length,
                      upcomingTasks: upcomingTasks,
                      totalTasks: totalTasks,
                    ),
                    const SizedBox(height: 16),
                    _buildAIPlannerSection(aiPlans),
                    const SizedBox(height: 16),
                    _buildUpNext(upNextTasks),
                    const SizedBox(height: 80), // space for FAB + bottom nav
                  ],
                ),
              ),
            ),
          ),

          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primaryBlue,
            onPressed: openAddTask,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          bottomNavigationBar: const AppBottomNavigation(
            currentIndex: NavigationIndex.dashboard,
          ),
        );
      },
    );
  }

  // ============================================================
  // 2. Greeting card — blue gradient card containing the greeting
  //    AND the Add Task / AI Plan small square buttons, like Figma.
  // ============================================================
  Widget _buildGreetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, AppColors.darkBlue],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good morning, ${ref.watch(userProvider)?.fullName ?? 'Student'}!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ready to crush your study goals today?',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              _squareAction(
                icon: Icons.check_circle_outline,
                label: 'Add Task',
                onTap: openAddTask,
              ),
              const SizedBox(width: 14),
              _squareAction(
                icon: Icons.auto_awesome,
                label: 'AI Plan',
                onTap: generateAiPlan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Small square icon button used inside the greeting card
  Widget _squareAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.card(context).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. Weekly Progress — circular indicator + 2 stat pills
  // ============================================================
  Widget _buildWeeklyProgress({
    required double weeklyProgress,
    required int completedTasks,
    required int todaysTasks,
    required int upcomingTasks,
    required int totalTasks,
  }) {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Weekly Progress',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 6),
              Icon(Icons.trending_up, color: AppColors.green, size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: weeklyProgress,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFE5E9F2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.green,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(weeklyProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Goal',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _statPill(
                      icon: Icons.check_circle,
                      iconColor: AppColors.green,
                      pillColor: const Color(0xFFE6F6EC),
                      title: '$completedTasks/$totalTasks',
                      subtitle: 'Task completed',
                    ),
                    const SizedBox(height: 10),
                    _statPill(
                      icon: Icons.event_note,
                      iconColor: AppColors.red,
                      pillColor: const Color(0xFFFCEAEA),
                      title: '$upcomingTasks',
                      subtitle: 'Upcoming tasks',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill({
    required IconData icon,
    required Color iconColor,
    required Color pillColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4. Daily Timeline — custom connected timeline (NOT ListTile)
  // ============================================================

  Widget _buildAIPlannerSection(List<AIPlanModel> aiPlans) {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's AI Study Plan",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AiPlannerScreen.routeName);
                },
                child: Text(
                  aiPlans.isEmpty ? "Generate" : "View",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (aiPlans.isEmpty)
            _buildEmptyAIState()
          else
            SizedBox(
              height: 250,
              child: AITimeline(
                aiPlans: aiPlans,
                allowMarkComplete: false,
                scrollable: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyAIState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 48,
            color: AppColors.primaryBlue,
          ),

          const SizedBox(height: 12),

          const Text(
            'No AI Study Plan Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          const Text(
            'Generate a personalized study plan to organize your tasks.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AiPlannerScreen.routeName);
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text("Generate AI Plan"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 5. Up Next — small horizontal cards instead of ListTiles
  // ============================================================
  Widget _buildUpNext(List<TaskModel> upNextTasks) {
    final colors = [
      AppColors.orange,
      AppColors.primaryBlue,
    ]; // accent color per card

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Up Next',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: openTasks,
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              upNextTasks.length > 2 ? 2 : upNextTasks.length,
              (i) {
                final task = upNextTasks[i];
                final color = colors[i % colors.length];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 0 ? 10 : 0),
                    child: _upNextCard(
                      color: color,
                      title: task.title,
                      subtitle: task.module,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _upNextCard({
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: openTasks,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, width: 28, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsStrip() {
    final totalAsync = ref.watch(taskCountProvider(null));
    final activeAsync = ref.watch(taskCountProvider(false));
    final doneAsync = ref.watch(taskCountProvider(true));

    Widget stat(String label, AsyncValue<int> value) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value.when(
                data: (v) => '$v',
                loading: () => '—',
                error: (_, __) => '—',
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
      child: Row(
        children: [
          stat('Total Tasks', totalAsync),
          stat('Active Tasks', activeAsync),
          stat('Completed', doneAsync),
        ],
      ),
    );
  }
}
