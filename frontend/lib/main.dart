import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/services/api_service.dart';
import 'ui/core/theme.dart';
import 'ui/features/login/login_view.dart';
import 'ui/features/dashboard/dashboard_view.dart';
import 'ui/features/profile/profile_view.dart';
import 'ui/features/analysis/analysis_view.dart';
import 'ui/features/import/import_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        path: '/dashboard',
        builder: (context, state) => const DashboardView(),
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
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        useMaterial3: true,
      ),
      // Light Theme Data
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        cardColor: AppColors.lightCard,
        dividerColor: AppColors.lightBorder,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.light).textTheme,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
