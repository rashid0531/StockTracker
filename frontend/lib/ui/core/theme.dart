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
        letterSpacing: -0.2,
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
        letterSpacing: -0.1,
      );

  TextStyle get bodyStyle => TextStyle(
        color: text,
        fontSize: 14,
      );

  Widget buildBackground({required Widget child}) {
    return PremiumBackground(isDark: isDark, child: child);
  }
}

class PremiumBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const PremiumBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  final ValueNotifier<Offset?> _hoverPositionNotifier = ValueNotifier<Offset?>(null);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _hoverPositionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      onHover: (event) {
        _hoverPositionNotifier.value = event.localPosition;
      },
      onExit: (event) {
        _hoverPositionNotifier.value = null;
      },
      child: Stack(
        children: [
          // 1. Base gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isDark
                      ? const [
                          Color(0xFF06080D),
                          Color(0xFF0C101A),
                          Color(0xFF111726),
                          Color(0xFF080B12),
                        ]
                      : const [
                          Color(0xFFF4F6F9),
                          Color(0xFFEBF0F7),
                          Color(0xFFF0F4F8),
                        ],
                ),
              ),
            ),
          ),

          // 2. Subtle Tech Grid Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _SubtleGridPainter(isDark: widget.isDark),
            ),
          ),

          // 3. Live Animated Pulsing & Floating Ambient Radial Orbs
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = _pulseAnimation.value;
              return Stack(
                children: [
                  // Top-Right Emerald Wealth Glow
                  Positioned(
                    top: -100 * scale,
                    right: -100 * scale,
                    child: Container(
                      width: 480 * scale,
                      height: 480 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: widget.isDark
                              ? [
                                  AppColors.positive.withValues(alpha: 0.28),
                                  AppColors.positive.withValues(alpha: 0.00),
                                ]
                              : [
                                  AppColors.positive.withValues(alpha: 0.18),
                                  AppColors.positive.withValues(alpha: 0.00),
                                ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom-Left Cyan / Deep Blue Asset Glow
                  Positioned(
                    bottom: -130 * scale,
                    left: -130 * scale,
                    child: Container(
                      width: 520 * scale,
                      height: 520 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: widget.isDark
                              ? [
                                  const Color(0xFF3B82F6).withValues(alpha: 0.24),
                                  const Color(0xFF3B82F6).withValues(alpha: 0.00),
                                ]
                              : [
                                  const Color(0xFF60A5FA).withValues(alpha: 0.15),
                                  const Color(0xFF60A5FA).withValues(alpha: 0.00),
                                ],
                        ),
                      ),
                    ),
                  ),

                  // Center Gold Ambient Glow
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.4 - (180 * scale),
                    left: MediaQuery.of(context).size.width * 0.5 - (180 * scale),
                    child: Container(
                      width: 360 * scale,
                      height: 360 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: widget.isDark
                              ? [
                                  const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                  const Color(0xFFF59E0B).withValues(alpha: 0.00),
                                ]
                              : [
                                  const Color(0xFFF59E0B).withValues(alpha: 0.06),
                                  const Color(0xFFF59E0B).withValues(alpha: 0.00),
                                ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 4. Interactive Hover Spotlight Glow
          ValueListenableBuilder<Offset?>(
            valueListenable: _hoverPositionNotifier,
            builder: (context, hoverPosition, child) {
              if (hoverPosition == null) return const SizedBox.shrink();
              return Positioned(
                left: hoverPosition.dx - 220,
                top: hoverPosition.dy - 220,
                child: IgnorePointer(
                  child: Container(
                    width: 440,
                    height: 440,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: widget.isDark
                            ? [
                                AppColors.positive.withValues(alpha: 0.18),
                                AppColors.positive.withValues(alpha: 0.00),
                              ]
                            : [
                                AppColors.positive.withValues(alpha: 0.12),
                                AppColors.positive.withValues(alpha: 0.00),
                              ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 5. Content overlay
          Positioned.fill(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _SubtleGridPainter extends CustomPainter {
  final bool isDark;
  _SubtleGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.025) : Colors.black.withValues(alpha: 0.02)
      ..strokeWidth = 0.6;

    const double step = 45.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SubtleGridPainter oldDelegate) => oldDelegate.isDark != isDark;
}
