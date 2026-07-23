import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  double _loadingProgress = 0.0;
  Timer? _progressTimer;
  String _statusText = "Initializing secure session...";

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    // Progress bar animation over 2.2 seconds
    _progressTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) return;
      setState(() {
        _loadingProgress += 0.02;
        if (_loadingProgress >= 0.35 && _loadingProgress < 0.7) {
          _statusText = "Loading market data engines...";
        } else if (_loadingProgress >= 0.7 && _loadingProgress < 0.95) {
          _statusText = "Preparing portfolio views...";
        } else if (_loadingProgress >= 1.0) {
          _loadingProgress = 1.0;
          _statusText = "Welcome to StockTracker";
          timer.cancel();
          _navigateToNextScreen();
        }
      });
    });
  }

  void _navigateToNextScreen() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: theme.buildBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Skip button in top right
              Positioned(
                top: 16,
                right: 20,
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Skip",
                        style: TextStyle(
                          color: theme.subtext,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.subtext),
                    ],
                  ),
                ),
              ),

              // Main Center Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo Container
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.positive.withValues(alpha: 0.35),
                                  blurRadius: 36,
                                  spreadRadius: 6,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(70),
                              child: Image.asset(
                                'assets/images/solorash_logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback vector icon logo
                                  return Container(
                                    color: const Color(0xFF0B101D),
                                    child: const Center(
                                      child: Text(
                                        "⚡",
                                        style: TextStyle(fontSize: 54),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Brand Titles
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              "SoloRash",
                              style: theme.titleStyle.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "FINANCIAL TECHNOLOGIES",
                              style: TextStyle(
                                color: AppColors.positive,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: theme.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("📈", style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "StockTracker Suite",
                                    style: theme.subtitleStyle.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Loading Progress Indicator
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _loadingProgress,
                                  minHeight: 4,
                                  backgroundColor: theme.border,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.positive),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _statusText,
                              style: theme.subtitleStyle.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Text(
                      "SoloRash Technologies © 2026",
                      style: theme.subtitleStyle.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
