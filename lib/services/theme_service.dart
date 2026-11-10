import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedThemeMode', mode);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('selectedThemeMode');

    if (mode == 'light') return ThemeMode.light;
    if (mode == 'dark') return ThemeMode.dark;

    return ThemeMode.system; // default
  }
}