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
                        Color(0xFF090A0F),
                        Color(0xFF141724),
                        Color(0xFF0E1018),
                      ]
                    : const [
                        Color(0xFFF3F5F8),
                        Color(0xFFEAEEF4),
                        Color(0xFFF1F4F7),
                      ],
              ),
            ),
          ),
        ),
        // Soft glowing mesh blobs
        if (isDark) ...[
          // Green glow for wealth growth
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x3B2E7D32), // More visible green glow
              ),
            ),
          ),
          // Deep navy/indigo glow for contrast
          Positioned(
            bottom: -120,
            left: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x333F51B5), // More visible indigo glow
              ),
            ),
          ),
        ] else ...[
          // Soft green/mint glow in light mode
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x3881C784),
              ),
            ),
          ),
          // Soft blue/slate glow in light mode
          Positioned(
            bottom: -140,
            left: -140,
            child: Container(
              width: 420,
              height: 420,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x3890CAF9),
              ),
            ),
          ),
        ],
        // BackdropFilter for a premium smooth blur effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 85.0, sigmaY: 85.0),
            child: const SizedBox.shrink(),
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
