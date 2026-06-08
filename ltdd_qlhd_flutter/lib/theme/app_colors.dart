import 'package:flutter/material.dart';

class AppColors {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(BuildContext context) {
    return isDark(context) ? const Color(0xFF0D1117) : const Color(0xFFF4F8FF);
  }

  static Color card(BuildContext context) {
    return isDark(context) ? const Color(0xFF161B22) : Colors.white;
  }

  static Color cardSoft(BuildContext context) {
    return isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFEAF3FF);
  }

  static Color title(BuildContext context) {
    return isDark(context) ? Colors.white : const Color(0xFF0D2240);
  }

  static Color subtitle(BuildContext context) {
    return isDark(context) ? const Color(0xFF9CA3AF) : const Color(0xFF6B82A0);
  }

  static Color muted(BuildContext context) {
    return isDark(context) ? const Color(0xFF7D8CA3) : const Color(0xFF91A4BC);
  }

  static Color divider(BuildContext context) {
    return isDark(context)
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE8EEF8);
  }

  static Color shadow(BuildContext context) {
    return isDark(context)
        ? Colors.black.withOpacity(0.25)
        : Colors.black.withOpacity(0.06);
  }

  static Color iconBox(BuildContext context) {
    return isDark(context) ? const Color(0xFF102A43) : const Color(0xFFEAF3FF);
  }

  static Color primary(BuildContext context) {
    return isDark(context) ? const Color(0xFF42A5F5) : const Color(0xFF1565C0);
  }

  static Color dangerBackground(BuildContext context) {
    return isDark(context) ? const Color(0xFF2A1116) : const Color(0xFFFFEEF0);
  }

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF00A8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
