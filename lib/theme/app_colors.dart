import 'package:flutter/material.dart';

class AppColors {
  // Brand/semantic accents — intentionally the same in light and dark,
  // this is a common convention so your brand color stays recognizable.
  static const Color primaryBlue = Color(0xFF1A56DB);
  static const Color green = Color(0xFF1E9E4D);
  static const Color red = Color(0xFFD64545);
  static const Color orange = Color(0xFFD9822B);
  static const Color darkBlue = Color(0xFF0B2C7A);

  // Light-mode surfaces (your original values, unchanged).
  static const Color bgColor = Color(0xFFEEF2F8);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  // Dark-mode surfaces.
  static const Color bgColorDark = Color(0xFF0F1218);
  static const Color cardColorDark = Color(0xFF1B1F27);
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  /// Theme-aware accessors — use these in place of the raw light-only
  /// constants above whenever a widget's color should flip with the theme.
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgColorDark : bgColor;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? cardColorDark
      : cardColor;

  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? textPrimaryDark
      : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? textSecondaryDark
      : textSecondary;

  static Color inputFill(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF242A35)
      : const Color(0xFFF8F9FC);

  static Color inputBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF3A4150)
      : const Color(0xFFE5E9F2);
}
