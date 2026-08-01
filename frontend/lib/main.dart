import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'data/services/api_service.dart';
import 'ui/core/theme.dart';
import 'ui/features/login/login_view.dart';
import 'ui/features/hub/hub_view.dart';
import 'ui/features/dashboard/dashboard_view.dart';
import 'ui/features/real_estate/real_estate_view.dart';
import 'ui/features/precious_metals/precious_metals_view.dart';
import 'ui/features/health/health_view.dart';
import 'ui/features/profile/profile_view.dart';
import 'ui/features/analysis/analysis_view.dart';
import 'ui/features/import/import_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('=== FLUTTER EXCEPTION DETECTED ===');
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack.toString());
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "⚠️ Application Error Caught",
                  style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
                Text(
                  details.stack.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => ApiService()),
      ],
      child: const WealthTrackerApp(),
    ),
  );
}

class WealthTrackerApp extends StatelessWidget {
  const WealthTrackerApp({super.key});

  // Declarative Routing configurations using GoRouter
  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/hub',
        builder: (context, state) => const HubView(),
      ),
      GoRoute(
        path: '/stocks',
        builder: (context, state) => const DashboardView(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardView(),
      ),
      GoRoute(
        path: '/real-estate',
        builder: (context, state) => const RealEstateView(),
      ),
      GoRoute(
        path: '/precious-metals',
        builder: (context, state) => const PreciousMetalsView(),
      ),
      GoRoute(
        path: '/health',
        builder: (context, state) => const HealthView(),
      ),
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportView(),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final profileId = state.pathParameters['id'] ?? '';
          return ProfileView(profileId: profileId);
        },
      ),
      GoRoute(
        path: '/analysis',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          final type = state.uri.queryParameters['type'] ?? 'stock';
          return AnalysisView(profileId: id, type: type);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'Wealth Tracker',
      themeMode: theme.themeMode,
      debugShowCheckedModeBanner: false,
      // Premium Dark Theme Data
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        cardColor: AppColors.darkCard,
        dividerColor: AppColors.darkBorder,
        useMaterial3: true,
      ),
      // Light Theme Data
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        cardColor: AppColors.lightCard,
        dividerColor: AppColors.lightBorder,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
