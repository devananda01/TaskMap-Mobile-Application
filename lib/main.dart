import 'package:flutter/material.dart';
import 'package:taskmap/providers/firebase_provider.dart';
import 'services/notification_service.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/dashboard/splash_screen.dart';
import 'screens/calendar/calendar_screen.dart';

import 'screens/tasks/task_management_screen.dart';
import 'screens/tasks/add_edit_task_screen.dart';

import 'screens/planner/Ai_planner_screen.dart';

import 'screens/netz/Upgrade_screen.dart';
import 'screens/auth/biometric_unlock_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/offline_banner.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
  await NotificationService().requestPermission();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    //final authState = ref.watch(authStateProvider);
    return MaterialApp(
      title: 'TaskMap',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        return Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
      home: /*authState.when(
        data: (user) {
          print("Auth state changed: ${user?.email}");

          return user != null ? DashboardScreen() : LoginScreen();
        },

        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),

        error: (error, stackTrace) =>
            const Scaffold(body: Center(child: Text("Something went wrong"))),
      ),*/
          //to run flutter run -d chrome --web-port=5000
          SplashScreen(),
      routes: {
        SplashScreen.routeName: (context) => SplashScreen(),
        BiometricUnlockScreen.routeName: (context) => BiometricUnlockScreen(),
        LoginScreen.routeName: (context) => LoginScreen(),
        RegisterScreen.routeName: (context) => RegisterScreen(),
        ForgotPasswordScreen.routeName: (context) => ForgotPasswordScreen(),
        ChangePasswordScreen.routeName: (context) => ChangePasswordScreen(),
        EmailVerificationScreen.routeName: (context) =>
            EmailVerificationScreen(),

        DashboardScreen.routeName: (context) => DashboardScreen(),

        TaskManagementScreen.routeName: (context) => TaskManagementScreen(),
        AddEditTaskScreen.routeName: (context) => AddEditTaskScreen(),

        CalendarScreen.routeName: (context) => CalendarScreen(),

        AiPlannerScreen.routeName: (context) => AiPlannerScreen(),

        UpgradeScreen.routeName: (context) => UpgradeScreen(),

        ProfileScreen.routeName: (context) => ProfileScreen(),
      },
    );
  }
}

class MainScreen extends StatelessWidget {
  static String get routeName => '/main';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Transport Expense Tracker'),
      ),
      body: const Center(child: Text('Hello, World!')),
    );
  }
}
