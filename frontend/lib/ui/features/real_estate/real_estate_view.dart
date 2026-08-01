import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/real_estate.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';

class RealEstateView extends StatefulWidget {
  const RealEstateView({super.key});

  @override
  State<RealEstateView> createState() => _RealEstateViewState();
}

class _RealEstateViewState extends State<RealEstateView> {
  final ApiService _apiService = ApiService();
  List<RealEstateAsset> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getRealEstateAssets();
      setState(() {
        _properties = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalValue => _properties.fold(0, (sum, p) => sum + p.currentValue);
  double get _totalMortgage => _properties.fold(0, (sum, p) => sum + p.mortgageBalance);
  double get _totalNetEquity => _totalValue - _totalMortgage;
  double get _totalMonthlyCashFlow => _properties.fold(0, (sum, p) => sum + p.monthlyCashFlow);

  void _showAddPropertyModal() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: "Condo");
    final buyPriceCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final mortCtrl = TextEditingController(text: "0");
    final rentCtrl = TextEditingController(text: "0");
    final expCtrl = TextEditingController(text: "0");
    final addrCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Real Estate Property 🏠", style: theme.cardTitleStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Property Name (e.g. Waterfront Condo)", labelStyle: TextStyle(color: theme.subtext)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addrCtrl,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Address", labelStyle: TextStyle(color: theme.subtext)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: buyPriceCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Purchase Price (\$)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: valCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Current Valuation (\$)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: mortCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Mortgage Balance (\$)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: rentCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Monthly Rent (\$)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || valCtrl.text.isEmpty) return;
                    final nav = Navigator.of(context);
                    await _apiService.addRealEstateAsset({
                      "property_name": nameCtrl.text,
                      "property_type": typeCtrl.text,
                      "purchase_price": double.tryParse(buyPriceCtrl.text) ?? 0.0,
                      "current_value": double.tryParse(valCtrl.text) ?? 0.0,
                      "mortgage_balance": double.tryParse(mortCtrl.text) ?? 0.0,
                      "monthly_rent_income": double.tryParse(rentCtrl.text) ?? 0.0,
                      "monthly_expenses": double.tryParse(expCtrl.text) ?? 0.0,
                      "address": addrCtrl.text,
                      "purchase_date": "2024-01-01",
                    });
                    nav.pop();
                    _loadData();
                  },
                  child: const Text("Add Property", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.text),
          onPressed: () => context.go('/hub'),
        ),
        title: Text("Real-Estate Portfolio 🏠", style: theme.cardTitleStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF3B82F6)),
            onPressed: _showAddPropertyModal,
          ),
        ],
      ),
      body: theme.buildBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
              : ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Summary Metrics Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.border, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("NET REAL ESTATE EQUITY", style: theme.subtitleStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            "\$${_totalNetEquity.toStringAsFixed(2)} CAD",
                            style: theme.cardTitleStyle.copyWith(fontSize: 28, color: const Color(0xFF3B82F6), fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetricItem("Property Value", "\$${_totalValue.toStringAsFixed(0)}", theme),
                              _buildMetricItem("Mortgages", "\$${_totalMortgage.toStringAsFixed(0)}", theme),
                              _buildMetricItem("Monthly Cash Flow", "+\$${_totalMonthlyCashFlow.toStringAsFixed(0)}/mo", theme, color: AppColors.positive),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text("Properties Owned (${_properties.length})", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    ..._properties.map((p) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p.propertyName, style: theme.cardTitleStyle.copyWith(fontSize: 15)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text(p.propertyType, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                              ],
                            ),
                            if (p.address != null) ...[
                              const SizedBox(height: 4),
                              Text(p.address!, style: theme.subtitleStyle.copyWith(fontSize: 11)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Value: \$${p.currentValue.toStringAsFixed(0)}", style: theme.bodyStyle.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text("Equity: \$${p.netEquity.toStringAsFixed(0)}", style: TextStyle(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
                                Text("Rent: \$${p.monthlyRentIncome.toStringAsFixed(0)}/mo", style: TextStyle(color: AppColors.positive, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String val, ThemeProvider theme, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.subtitleStyle.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: theme.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13, color: color ?? theme.text)),
      ],
    );
  }
}
