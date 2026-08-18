import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';
import 'profile_view.dart';
import 'widgets/modern_donut_chart.dart';

class AnalyticsView extends StatelessWidget {
  final String profileId;

  const AnalyticsView({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(
        apiService: ApiService(),
        profileId: profileId,
      )..loadProfileDetails(),
      child: const _AnalyticsViewContent(),
    );
  }
}

class _AnalyticsViewContent extends StatefulWidget {
  const _AnalyticsViewContent();

  @override
  State<_AnalyticsViewContent> createState() => _AnalyticsViewContentState();
}

class _AnalyticsViewContentState extends State<_AnalyticsViewContent> {
  final List<Color> _donutColors = const [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF59E0B), // Amber
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final viewModel = Provider.of<ProfileViewModel>(context);

    if (viewModel.isLoading) {
      return Scaffold(
        backgroundColor: theme.bg,
        appBar: AppBar(
          backgroundColor: theme.card,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.text),
            onPressed: () => context.pop(),
          ),
          title: Text("Analytics", style: theme.titleStyle),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final stockItems = viewModel.stockAllocItems;
    final sectorItems = viewModel.sectorAllocItems;

    for (int i = 0; i < stockItems.length; i++) {
      stockItems[i].color = _donutColors[i % _donutColors.length];
    }
    for (int i = 0; i < sectorItems.length; i++) {
      sectorItems[i].color = _donutColors[(i + 2) % _donutColors.length];
    }

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.text),
          onPressed: () => context.pop(),
        ),
        title: Text("Analytics", style: theme.titleStyle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (stockItems.isNotEmpty)
              ModernGridDonutCard(
                items: stockItems,
                title: "Stock Weight",
                subtitle: "${stockItems.length} Assets",
                centerLabel: "Stocks",
                onPress: () => context.push(
                  "/analysis?id=${viewModel.profileId}&type=stock",
                ),
              ),
            if (sectorItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              ModernGridDonutCard(
                items: sectorItems,
                title: "Sector Weight",
                subtitle: "${sectorItems.length} Sectors",
                centerLabel: "Sectors",
                onPress: () => context.push(
                  "/analysis?id=${viewModel.profileId}&type=sector",
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
