import 'package:flutter/material.dart';
import 'dart:ui';

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

  Widget buildBackground({required Widget child}) {
    return PremiumBackground(
      isDark: isDark,
      child: child,
    );
  }
}

class PremiumBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const PremiumBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        Color(0xFF060708),
                        Color(0xFF0D1017),
                        Color(0xFF080A0E),
                      ]
                    : const [
                        Color(0xFFF6F8FA),
                        Color(0xFFEDF1F6),
                        Color(0xFFF4F6F9),
                      ],
              ),
            ),
          ),
        ),
        // Soft glowing mesh blobs
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90, tileMode: TileMode.decal),
            child: Stack(
              children: [
                if (isDark) ...[
                  // Green glow for wealth growth
                  Positioned(
                    top: -80,
                    right: -80,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x1A2E7D32),
                      ),
                    ),
                  ),
                  // Deep navy/indigo glow for contrast
                  Positioned(
                    bottom: -100,
                    left: -100,
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x121E3A8A),
                      ),
                    ),
                  ),
                ] else ...[
                  // Soft green/mint glow in light mode
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x2481C784),
                      ),
                    ),
                  ),
                  // Soft blue/slate glow in light mode
                  Positioned(
                    bottom: -120,
                    left: -120,
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x2990CAF9),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Content overlay
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
