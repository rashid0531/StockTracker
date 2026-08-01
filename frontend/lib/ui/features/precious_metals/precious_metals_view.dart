import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/precious_metal.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';

class PreciousMetalsView extends StatefulWidget {
  const PreciousMetalsView({super.key});

  @override
  State<PreciousMetalsView> createState() => _PreciousMetalsViewState();
}

class _PreciousMetalsViewState extends State<PreciousMetalsView> {
  final ApiService _apiService = ApiService();
  List<PreciousMetalAsset> _metals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getPreciousMetals();
      setState(() {
        _metals = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalValue => _metals.fold(0, (sum, m) => sum + m.totalCurrentValue);
  double get _totalWeightOz => _metals.fold(0, (sum, m) => sum + m.weightOz);
  double get _totalGainLoss => _metals.fold(0, (sum, m) => sum + m.totalGainLoss);

  void _showAddMetalModal() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final typeCtrl = TextEditingController(text: "Gold");
    final formCtrl = TextEditingController(text: "1 oz Bar");
    final wtCtrl = TextEditingController();
    final buyPriceCtrl = TextEditingController();
    final spotCtrl = TextEditingController();
    final locCtrl = TextEditingController(text: "Home Safe");

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
              Text("Add Precious Metal Asset 🥇", style: theme.cardTitleStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: typeCtrl,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Metal Type (Gold, Silver)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: formCtrl,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Form (Bar, Coin)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: wtCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Weight (troy oz)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: buyPriceCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Buy Price/oz (\$)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: spotCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Spot Price/oz (\$)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: locCtrl,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Vault / Location", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (wtCtrl.text.isEmpty || buyPriceCtrl.text.isEmpty) return;
                    final nav = Navigator.of(context);
                    await _apiService.addPreciousMetalAsset({
                      "metal_type": typeCtrl.text,
                      "form": formCtrl.text,
                      "weight_oz": double.tryParse(wtCtrl.text) ?? 0.0,
                      "purity_percent": 99.99,
                      "purchase_price_per_oz": double.tryParse(buyPriceCtrl.text) ?? 0.0,
                      "current_spot_price_per_oz": double.tryParse(spotCtrl.text) ?? 0.0,
                      "storage_location": locCtrl.text,
                      "purchase_date": "2024-01-01",
                    });
                    nav.pop();
                    _loadData();
                  },
                  child: const Text("Add Precious Metal", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: Text("Precious Metals Vault 🥇", style: theme.cardTitleStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFF59E0B)),
            onPressed: _showAddMetalModal,
          ),
        ],
      ),
      body: theme.buildBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
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
                          Text("TOTAL VAULT VALUE", style: theme.subtitleStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            "\$${_totalValue.toStringAsFixed(2)} CAD",
                            style: theme.cardTitleStyle.copyWith(fontSize: 28, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetricItem("Total Weight", "${_totalWeightOz.toStringAsFixed(1)} oz", theme),
                              _buildMetricItem("Unrealized Gain", "+\$${_totalGainLoss.toStringAsFixed(2)}", theme, color: AppColors.positive),
                              _buildMetricItem("Metals Count", "${_metals.length} Assets", theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text("Physical Holdings (${_metals.length})", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    ..._metals.map((m) {
                      String icon = "🪙";
                      if (m.metalType.toLowerCase() == "gold") icon = "🥇";
                      if (m.metalType.toLowerCase() == "silver") icon = "🥈";
                      if (m.metalType.toLowerCase() == "bronze") icon = "🥉";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${m.metalType} (${m.form})", style: theme.cardTitleStyle.copyWith(fontSize: 14)),
                                  Text("Vault: ${m.storageLocation}", style: theme.subtitleStyle.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("\$${m.totalCurrentValue.toStringAsFixed(2)}", style: theme.cardTitleStyle.copyWith(fontSize: 14, color: const Color(0xFFF59E0B))),
                                Text("${m.weightOz} oz @ \$${m.currentSpotPricePerOz}/oz", style: theme.subtitleStyle.copyWith(fontSize: 10)),
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
