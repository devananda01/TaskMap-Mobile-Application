import 'package:flutter/material.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/tasks/task_management_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/planner/Ai_planner_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../theme/app_colors.dart';

class NavigationIndex {
  static const int dashboard = 0;
  static const int tasks = 1;
  static const int calendar = 2;
  static const int planner = 3;
  static const int profile = 4;
}

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case NavigationIndex.dashboard:
        Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
        break;
      case NavigationIndex.tasks:
        Navigator.pushReplacementNamed(context, TaskManagementScreen.routeName);
        break;
      case NavigationIndex.calendar:
        Navigator.pushReplacementNamed(context, CalendarScreen.routeName);
        break;
      case NavigationIndex.planner:
        Navigator.pushReplacementNamed(context, AiPlannerScreen.routeName);
        break;
      case NavigationIndex.profile:
        Navigator.pushReplacementNamed(context, ProfileScreen.routeName);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.card(context),
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textSecondaryOf(context),
      onTap: (index) => _onTap(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.checklist_rounded),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_rounded),
          label: 'Planner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
