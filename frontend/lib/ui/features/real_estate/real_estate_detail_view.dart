import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/real_estate.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';
import '../profile/widgets/modern_history_chart.dart'; // Using the chart widget from profile view
import '../../../data/models/profile.dart'; // ChartPoint

class RealEstateDetailView extends StatefulWidget {
  final RealEstateAsset? asset;
  final String assetId;

  const RealEstateDetailView({super.key, this.asset, required this.assetId});

  @override
  State<RealEstateDetailView> createState() => _RealEstateDetailViewState();
}

class _RealEstateDetailViewState extends State<RealEstateDetailView> {
  late ApiService _apiService;
  RealEstateAsset? _asset;
  bool _isLoading = true;
  List<ChartPoint> _projectionPoints = [];

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
    _apiService = Provider.of<ApiService>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    // If we only got ID, we would fetch from API, but for now we expect the object to be passed via GoRouter extra.
    // However, if we need to fetch projection, we do it here.
    if (_asset != null) {
      try {
        final rawData = await _apiService.getRealEstateProjection(_asset!.id, _asset!.currentValue);
        _projectionPoints = rawData.map((d) {
          return ChartPoint(
            date: d["year"],
            value: (d["projected_value"] as num).toDouble(),
          );
        }).toList();
      } catch (e) {
        debugPrint("Error fetching projection: $e");
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.bg,
        appBar: AppBar(backgroundColor: theme.card, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_asset == null) {
      return Scaffold(
        backgroundColor: theme.bg,
        appBar: AppBar(backgroundColor: theme.card, elevation: 0),
        body: const Center(child: Text("Asset not found")),
      );
    }

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.text),
          onPressed: () => context.pop(),
        ),
        title: Text(_asset!.propertyName, style: theme.cardTitleStyle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Usage Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _asset!.isPrimaryResidence 
                    ? AppColors.positive.withValues(alpha: 0.15)
                    : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _asset!.isPrimaryResidence ? AppColors.positive : const Color(0xFF3B82F6),
                )
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _asset!.isPrimaryResidence ? Icons.home_rounded : Icons.monetization_on_rounded,
                    color: _asset!.isPrimaryResidence ? AppColors.positive : const Color(0xFF3B82F6),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _asset!.isPrimaryResidence ? "Primary Residence" : "Investment Property",
                    style: TextStyle(
                      color: _asset!.isPrimaryResidence ? AppColors.positive : const Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Financial Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("PROPERTY VALUATION", style: theme.subtitleStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    "\$${_asset!.currentValue.toStringAsFixed(0)}",
                    style: theme.cardTitleStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem("Purchase Price", "\$${_asset!.purchasePrice.toStringAsFixed(0)}", theme),
                      _buildMetricItem("Mortgage Left", "\$${_asset!.mortgageBalance.toStringAsFixed(0)}", theme),
                      _buildMetricItem("Equity Earned", "\$${_asset!.netEquity.toStringAsFixed(0)}", theme, color: AppColors.positive),
                    ],
                  ),
                  if (!_asset!.isPrimaryResidence) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricItem("Monthly Rent", "\$${_asset!.monthlyRentIncome.toStringAsFixed(0)}", theme),
                        _buildMetricItem("Monthly Expenses", "\$${_asset!.monthlyExpenses.toStringAsFixed(0)}", theme),
                        _buildMetricItem("Net Cashflow", "+\$${_asset!.monthlyCashFlow.toStringAsFixed(0)}/mo", theme, color: AppColors.positive),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Graph Section
            Text("35-Year Price Projection", style: theme.cardTitleStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Based on current market trends & dynamic modeling.", style: theme.subtitleStyle),
            const SizedBox(height: 16),
            
            if (_projectionPoints.isNotEmpty)
              Container(
                height: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.border, width: 1.5),
                ),
                child: ModernHistoryChart(
                  points: _projectionPoints,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String val, ThemeProvider theme, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.subtitleStyle.copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: theme.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 14, color: color ?? theme.text)),
      ],
    );
  }
}
