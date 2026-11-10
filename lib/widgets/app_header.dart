import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onProfilePressed;

  const AppHeader({super.key, this.onProfilePressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'TaskMap',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onProfilePressed,
          tooltip: 'Profile',
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: isDark
                ? const Color(0xFF1E2A4A)
                : const Color(0xFFE9EEFC),
            child: const Icon(
              Icons.person,
              color: AppColors.primaryBlue,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
