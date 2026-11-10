import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/theme_service.dart';

final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

final themeProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  final service = ref.read(themeServiceProvider);
  return ThemeController(service);
});

class ThemeController extends StateNotifier<ThemeMode> {
  final ThemeService service;

  ThemeController(this.service) : super(ThemeMode.system) {
    loadThemeMode();
  }

  Future<void> loadThemeMode() async {
    state = await service.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await service.setThemeMode(mode.name); // 'light' / 'dark' / 'system'
  }
}
