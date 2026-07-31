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
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bg,
      child: child,
    );
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

class _PremiumBackgroundState extends State<PremiumBackground> {
  final ValueNotifier<Offset?> _hoverPositionNotifier = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
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
          // Base gradient background (opaque)
          Positioned.fill(
            child: Container(
              color: widget.isDark ? const Color(0xFF090A0F) : const Color(0xFFF3F5F8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.isDark
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
          ),
          // Soft glowing mesh radial gradient blobs (no BackdropFilter layer bug)
          if (widget.isDark) ...[
            // Green radial glow for wealth growth
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 450,
                height: 450,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x404CAF50),
                      Color(0x004CAF50),
                    ],
                  ),
                ),
              ),
            ),
            // Deep navy/indigo radial glow for contrast
            Positioned(
              bottom: -120,
              left: -120,
              child: Container(
                width: 500,
                height: 500,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x385C6BC0),
                      Color(0x005C6BC0),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Soft green/mint radial glow in light mode
            Positioned(
              top: -120,
              right: -120,
              child: Container(
                width: 450,
                height: 450,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x3581C784),
                      Color(0x0081C784),
                    ],
                  ),
                ),
              ),
            ),
            // Soft blue/slate radial glow in light mode
            Positioned(
              bottom: -140,
              left: -140,
              child: Container(
                width: 520,
                height: 520,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x3590CAF9),
                      Color(0x0090CAF9),
                    ],
                  ),
                ),
              ),
            ),
          ],
          // Interactive Hover Responsive Radial Glow Blob
          ValueListenableBuilder<Offset?>(
            valueListenable: _hoverPositionNotifier,
            builder: (context, hoverPosition, child) {
              if (hoverPosition == null) return const SizedBox.shrink();
              return Positioned(
                left: hoverPosition.dx - 200,
                top: hoverPosition.dy - 200,
                child: IgnorePointer(
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: widget.isDark
                            ? const [
                                Color(0x4000E676),
                                Color(0x0000E676),
                              ]
                            : const [
                                Color(0x304CAF50),
                                Color(0x004CAF50),
                              ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Content overlay
          Positioned.fill(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
