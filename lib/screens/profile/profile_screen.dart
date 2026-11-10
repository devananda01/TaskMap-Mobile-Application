import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskmap/models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../utils/app_snackbar.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/white_card.dart';
// add to imports
import '../../providers/biometric_provider.dart';

import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  static const String routeName = "/profile";

  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ── State ─────────────────────────────────────────────────────────────────

  UserModel? get user => ref.read(userProvider);

  String get userName => user?.fullName ?? "TaskMap User";

  String get userEmail => user?.email ?? "";

  String get userRole => (user?.isPremium ?? false)
      ? "Student • TaskMap Pro"
      : "Student • TaskMap Free";
  /* Toggle states
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;*/

  // ── Methods ───────────────────────────────────────────────────────────────

  //void openEditProfile() {
  //  Navigator.pushNamed(context, '/edit-profile');
  // }

  void openChangePassword() {
    Navigator.pushNamed(context, '/change-password');
  }

  void openUpgrade() {
    Navigator.pushNamed(context, '/upgrade');
  }

  /* void toggleNotifications(bool value) {
    setState(() => notificationsEnabled = value);
    // TODO: ref.read(settingsProvider.notifier).setNotifications(value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Notifications enabled' : 'Notifications disabled',
        ),
      ),
    );
  }

  void toggleDarkMode(bool value) {
    setState(() => darkModeEnabled = value);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dark mode coming soon!')));
  }*/

  void logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () async {
              Navigator.pop(context);

              await ref.read(userProvider.notifier).logout();
              ref.invalidate(biometricProvider);

              if (!mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final tasksAsync = ref.watch(taskProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return tasksAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (error, stack) =>
          Scaffold(body: Center(child: Text(error.toString()))),

      data: (tasks) {
        final totalTasks = tasks.length;

        final tasksCompleted = tasks.where((task) => task.isDone).length;

        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(
                    onProfilePressed: () {
                      Navigator.pushNamed(context, ProfileScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildAvatarCard(),
                  const SizedBox(height: 16),
                  _buildStatsRow(totalTasks, tasksCompleted),
                  const SizedBox(height: 16),
                  _buildAccountSection(user),
                  const SizedBox(height: 16),
                  _buildSecuritySection(),
                  const SizedBox(height: 16),
                  _buildThemeSection(),
                  const SizedBox(height: 16),
                  _buildUpgradeBanner(user),
                  const SizedBox(height: 16),
                  _buildLogoutButton(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: NavigationIndex.profile,
          ),
        );
      },
    );
  }

  // ── Page header ────────────────────────────────────────────────────────────

  // ── Avatar card ────────────────────────────────────────────────────────────
  Widget _buildAvatarCard() {
    return WhiteCard(
      child: Row(
        children: [
          // Avatar circle with initials
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primaryBlue.withOpacity(0.12),
            child: Text(
              // Take first letter of each word in the name
              userName.split(' ').map((w) => w[0]).take(2).join().toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  userEmail,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userRole,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(int totalTasks, int tasksCompleted) {
    return Row(
      children: [
        Expanded(
          child: _statBox(
            icon: Icons.check_circle_rounded,
            color: AppColors.green,
            value: '$tasksCompleted/$totalTasks',
            label: 'Completed Tasks',
          ),
        ),

        const SizedBox(width: 10),
        if (user?.isPremium ?? false)
          Expanded(
            child: _statBox(
              icon: Icons.workspace_premium_rounded,
              color: Colors.amber,
              value: 'Unlimited',
              label: 'AI plans',
            ),
          )
        else
          Expanded(
            child: _statBox(
              icon: Icons.auto_awesome_rounded,
              color: AppColors.primaryBlue,
              value: '${user?.aiUsageCount ?? 0}/3',
              label: 'AI Plans',
            ),
          ),
      ],
    );
  }

  Widget _statBox({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Account settings ───────────────────────────────────────────────────────
  Widget _buildAccountSection(UserModel user) {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Account'),
          const SizedBox(height: 10),
          /* _settingsTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profile',
            onTap: openEditProfile,
          ),*/
          _divider(),
          _settingsTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: openChangePassword,
          ),
          /*_divider(),
          _settingsTile(
            icon: user.emailVerified
                ? Icons.verified
                : Icons.mark_email_unread_outlined,
            label: user.emailVerified ? 'Email Verified' : 'Verify Email',
            onTap: () async {
              if (!user.emailVerified) {
                await FirebaseService().sendEmailVerification();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verification email sent.')),
                );
              }
            },
          ),
          _divider(),
          _settingsTile(
            icon: Icons.school_outlined,
            label: 'Academic Info',
            onTap: () {
              // TODO: navigate to academic info page
            },
          ),*/
        ],
      ),
    );
  }

  // ── Preferences ────────────────────────────────────────────────────────────
  /*Widget _buildPreferencesSection() {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Preferences'),
          const SizedBox(height: 10),
          _toggleTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            value: notificationsEnabled,
            onChanged: toggleNotifications,
          ),
          _divider(),
          _toggleTile(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            value: darkModeEnabled,
            onChanged: toggleDarkMode,
          ),
          
        ],
      ),
    );
  }
*/
  // ── Upgrade banner ─────────────────────────────────────────────────────────
  Widget _buildUpgradeBanner(UserModel user) {
    if (user.isPremium) {
      return InkWell(
        onTap: openUpgrade,
        borderRadius: BorderRadius.circular(16),
        child: WhiteCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.green,
                  size: 26,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRO MEMBER',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Unlimited AI Study Plan Generations',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 15,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),

                        Text(
                          user.premiumExpiry == null
                              ? 'Premium expires: 12/08/2026'
                              : 'Premium expires: ${user.premiumExpiry!.day}/${user.premiumExpiry!.month}/${user.premiumExpiry!.year}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: openUpgrade,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryBlue, Color(0xFF0B2C7A)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Unlock unlimited AI plans & analytics.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
  color: AppColors.card(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '\$3.99/mo',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout button ──────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: logout,
        icon: const Icon(Icons.logout_rounded, color: AppColors.red, size: 18),
        label: const Text(
          'Log Out',
          style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  // Standard tappable row with left icon, label, and chevron
  Widget _settingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Tile with a toggle switch on the right instead of a chevron
  Widget _toggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: Color(0xFFF0F2F8));
  }

  Widget _buildSecuritySection() {
    final biometric = ref.watch(biometricProvider);
   

    if (biometric.loading) return const CircularProgressIndicator();

    if (!biometric.available) return const SizedBox.shrink();

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Security'),
          const SizedBox(height: 10),
          _toggleTile(
            icon: Icons.fingerprint_rounded,
            label: 'Biometric Login',
            value: biometric.enabled,
            onChanged: (value) async {
              if (value) {
                final ok = await ref.read(biometricProvider.notifier).enable();
                if (!mounted) return;
                if (ok) {
                  AppSnackbar.success(context, 'Biometric login enabled.');
                } else {
                  AppSnackbar.error(
                    context,
                    'Biometric authentication failed.',
                  );
                }
              } else {
                await ref.read(biometricProvider.notifier).disable();
                if (!mounted) return;
                AppSnackbar.success(context, 'Biometric login disabled.');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    final themeMode = ref.watch(themeProvider);

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Appearance'),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.settings_suggest_rounded),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selected) {
              ref.read(themeProvider.notifier).setThemeMode(selected.first);
            },
          ),
        ],
      ),
    );
  }
}
