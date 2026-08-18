import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';
import 'profile_view.dart';
import 'widgets/modern_donut_chart.dart';

class DividendAnalyticsView extends StatelessWidget {
  final String profileId;

  const DividendAnalyticsView({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(
        apiService: Provider.of<ApiService>(context, listen: false),
        profileId: profileId,
      )..loadProfileDetails(),
      child: const _DividendAnalyticsViewContent(),
    );
  }
}

class _DividendAnalyticsViewContent extends StatefulWidget {
  const _DividendAnalyticsViewContent({super.key});

  @override
  State<_DividendAnalyticsViewContent> createState() => _DividendAnalyticsViewContentState();
}

class _DividendAnalyticsViewContentState extends State<_DividendAnalyticsViewContent> {
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
          title: Text("Dividend Analytics", style: theme.titleStyle),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final divItems = viewModel.dividendContribItems;

    for (int i = 0; i < divItems.length; i++) {
      divItems[i].color = _donutColors[(i + 4) % _donutColors.length];
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
        title: Text("Dividend Analytics", style: theme.titleStyle),
      ),
      body: SafeArea(
        child: divItems.isEmpty
            ? Center(
                child: Text(
                  "No dividend data available",
                  style: TextStyle(color: theme.subtext, fontSize: 16),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  ModernGridDonutCard(
                    items: divItems,
                    title: "Dividend Contribution",
                    subtitle: "${divItems.length} Payers",
                    centerLabel: "Dividends",
                    onPress: () => context.push(
                      "/analysis?id=${viewModel.profileId}&type=dividend",
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
