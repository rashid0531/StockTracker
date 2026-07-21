import 'package:flutter/material.dart';

class AppColors {
  // Common Colors
  static const Color positive = Color(0xFF4CAF50);
  static const Color negative = Color(0xFFEF5350);
  static const Color dividend = Color(0xFFFFB300);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0C0D0E);
  static const Color darkCard = Color(0xFF16171A);
  static const Color darkBorder = Color(0xFF222429);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSubtext = Color(0xFF888C94);

  // Light Mode Colors
  static const Color lightBg = Color(0xFFF5F6F8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightText = Color(0xFF111827);
  static const Color lightSubtext = Color(0xFF6B7280);
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default to premium dark theme

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Get colors matching active state
  Color get bg => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get card => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get text => isDark ? AppColors.darkText : AppColors.lightText;
  Color get subtext => isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

  // Custom text styles
  TextStyle get titleStyle => TextStyle(
        color: text,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      );

  TextStyle get subtitleStyle => TextStyle(
        color: subtext,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  TextStyle get cardTitleStyle => TextStyle(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );

  TextStyle get bodyStyle => TextStyle(
        color: text,
        fontSize: 14,
      );
}
