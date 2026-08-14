import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';
import 'profile_view.dart';
import 'widgets/modern_donut_chart.dart';

class AnalyticsView extends StatelessWidget {
  final String profileId;

  const AnalyticsView({Key? key, required this.profileId}) : super(key: key);

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
  const _AnalyticsViewContent({Key? key}) : super(key: key);

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
    final divItems = viewModel.dividendContribItems;

    for (int i = 0; i < stockItems.length; i++) {
      stockItems[i].color = _donutColors[i % _donutColors.length];
    }
    for (int i = 0; i < sectorItems.length; i++) {
      sectorItems[i].color = _donutColors[(i + 2) % _donutColors.length];
    }
    for (int i = 0; i < divItems.length; i++) {
      divItems[i].color = _donutColors[(i + 4) % _donutColors.length];
    }

    final isValuation = viewModel.chartMode == "VALUATION";

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
            _buildModeToggle(viewModel, theme),
            const SizedBox(height: 24),
            if (isValuation) ...[
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
            ] else ...[
              if (divItems.isNotEmpty)
                ModernGridDonutCard(
                  items: divItems,
                  title: "Dividend Contribution",
                  subtitle: "${divItems.length} Payers",
                  centerLabel: "Dividends",
                  onPress: () => context.push(
                    "/analysis?id=${viewModel.profileId}&type=dividend",
                  ),
                ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(ProfileViewModel viewModel, ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _buildModeSegment(
              viewModel: viewModel,
              label: "VALUATION",
              value: "VALUATION",
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildModeSegment(
              viewModel: viewModel,
              label: "DIVIDENDS",
              value: "DIVIDEND",
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSegment({
    required ProfileViewModel viewModel,
    required String label,
    required String value,
    required ThemeProvider theme,
  }) {
    final isActive = viewModel.chartMode == value;
    return InkWell(
      onTap: () => viewModel.setChartMode(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.border : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? theme.text : theme.subtext,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
