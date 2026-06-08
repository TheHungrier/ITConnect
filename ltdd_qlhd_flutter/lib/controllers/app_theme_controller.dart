import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  static const String _themeKey = 'isDarkMode';

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_themeKey) ?? false;

    themeMode.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_themeKey, value);

    themeMode.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  static bool get isDarkMode {
    return themeMode.value == ThemeMode.dark;
  }
}
