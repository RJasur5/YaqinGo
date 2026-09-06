import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';

class ThemeService {
  static const _themeKey = 'yaqin_theme_mode';
  
  final ValueNotifier<AppThemeMode> themeNotifier = ValueNotifier(AppThemeMode.light);

  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    themeNotifier.value = AppThemeMode.values[themeIndex];
  }

  void setTheme(AppThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  AppThemeMode get currentMode => themeNotifier.value;
}
