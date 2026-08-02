import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../theme.dart';

class CreatePillarProfileModal extends StatefulWidget {
  final VoidCallback onProfileCreated;

  const CreatePillarProfileModal({
    super.key,
    required this.onProfileCreated,
  });

  static void show(BuildContext context, {required VoidCallback onProfileCreated}) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => CreatePillarProfileModal(onProfileCreated: onProfileCreated),
    );
  }

  @override
  State<CreatePillarProfileModal> createState() => _CreatePillarProfileModalState();
}

class _CreatePillarProfileModalState extends State<CreatePillarProfileModal> {
  final ApiService _apiService = ApiService();
  int _currentStep = 1; // Step 1: Select Pillar, Step 2: Fill Specific Asset Form
  String _selectedPillar = "Stocks";
  bool _isSubmitting = false;

  // Controllers for Stocks
  final _stockNameCtrl = TextEditingController();
  String _stockType = "TFSA";
  String _stockCountry = "Canada";

  // Controllers for Real Estate
  final _reNameCtrl = TextEditingController();
  final String _reType = "Condo";
  final _reValCtrl = TextEditingController();
  final _reMortCtrl = TextEditingController();
  final _reRentCtrl = TextEditingController();
  final _reExpCtrl = TextEditingController();
  final _reAddrCtrl = TextEditingController();

  // Controllers for Precious Metals
  String _pmMetalType = "Gold";
  final String _pmForm = "1 oz Bar";
  final _pmWeightCtrl = TextEditingController();
  final _pmBuyPriceCtrl = TextEditingController();
  final _pmSpotPriceCtrl = TextEditingController();
  final _pmLocCtrl = TextEditingController(text: "Home Safe");

  // Controllers for Health
  String _healthType = "Weight";
  final _healthValCtrl = TextEditingController();
  String _healthUnit = "kg";
  final _healthNotesCtrl = TextEditingController();

  final Map<String, Map<String, dynamic>> _pillarMeta = {
    "Stocks": {
      "icon": "📈",
      "color": AppColors.positive,
      "label": "Stocks & Equities",
      "subtitle": "Create TFSA, RRSP, 401(k), Taxable, or Crypto profile",
      "route": "/stocks",
    },
    "Real-Estate": {
      "icon": "🏠",
      "color": const Color(0xFF3B82F6),
      "label": "Real-Estate Property",
      "subtitle": "Add Condo, Rental, Commercial, or REIT property asset",
      "route": "/real-estate",
    },
    "Precious Metals": {
      "icon": "🥇",
      "color": const Color(0xFFF59E0B),
      "label": "Precious Metals Vault",
      "subtitle": "Add Physical Gold, Silver, Platinum, or Bronze holdings",
      "route": "/precious-metals",
    },
    "Health": {
      "icon": "❤️",
      "color": const Color(0xFFEC4899),
      "label": "Health & Wellness Log",
      "subtitle": "Log Weight, Resting Heart Rate, Sleep Quality, or Vitals",
      "route": "/health",
    },
  };

  @override
  void dispose() {
    _stockNameCtrl.dispose();
    _reNameCtrl.dispose();
    _reValCtrl.dispose();
    _reMortCtrl.dispose();
    _reRentCtrl.dispose();
    _reExpCtrl.dispose();
    _reAddrCtrl.dispose();
    _pmWeightCtrl.dispose();
    _pmBuyPriceCtrl.dispose();
    _pmSpotPriceCtrl.dispose();
    _pmLocCtrl.dispose();
    _healthValCtrl.dispose();
    _healthNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final nav = Navigator.of(context);
      final router = GoRouter.of(context);
      final targetRoute = _pillarMeta[_selectedPillar]!["route"] as String;

      if (_selectedPillar == "Stocks") {
        if (_stockNameCtrl.text.trim().isEmpty) return;
        await _apiService.createProfile(
          name: _stockNameCtrl.text.trim(),
          country: _stockCountry,
          type: _stockType,
          pillarCategory: "Stocks",
        );
      } else if (_selectedPillar == "Real-Estate") {
        if (_reNameCtrl.text.trim().isEmpty || _reValCtrl.text.trim().isEmpty) return;
        await _apiService.addRealEstateAsset({
          "property_name": _reNameCtrl.text.trim(),
          "property_type": _reType,
          "purchase_price": double.tryParse(_reValCtrl.text) ?? 0.0,
          "current_value": double.tryParse(_reValCtrl.text) ?? 0.0,
          "mortgage_balance": double.tryParse(_reMortCtrl.text) ?? 0.0,
          "monthly_rent_income": double.tryParse(_reRentCtrl.text) ?? 0.0,
          "monthly_expenses": double.tryParse(_reExpCtrl.text) ?? 0.0,
          "address": _reAddrCtrl.text.trim(),
          "purchase_date": "2026-01-01",
        });
      } else if (_selectedPillar == "Precious Metals") {
        if (_pmWeightCtrl.text.trim().isEmpty || _pmSpotPriceCtrl.text.trim().isEmpty) return;
        await _apiService.addPreciousMetalAsset({
          "metal_type": _pmMetalType,
          "form": _pmForm,
          "weight_oz": double.tryParse(_pmWeightCtrl.text) ?? 0.0,
          "purity_percent": 99.99,
          "purchase_price_per_oz": double.tryParse(_pmBuyPriceCtrl.text) ?? 0.0,
          "current_spot_price_per_oz": double.tryParse(_pmSpotPriceCtrl.text) ?? 0.0,
          "storage_location": _pmLocCtrl.text.trim(),
          "purchase_date": "2026-01-01",
        });
      } else if (_selectedPillar == "Health") {
        if (_healthValCtrl.text.trim().isEmpty) return;
        await _apiService.addHealthMetric({
          "metric_type": _healthType,
          "value": double.tryParse(_healthValCtrl.text) ?? 0.0,
          "unit": _healthUnit,
          "notes": _healthNotesCtrl.text.trim(),
          "logged_at": "2026-08-02",
        });
      }

      nav.pop();
      widget.onProfileCreated();
      router.push(targetRoute);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_currentStep == 2)
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: theme.text),
                      onPressed: () => setState(() => _currentStep = 1),
                    ),
                  Text(
                    _currentStep == 1 ? "Select Asset Category 🎯" : "Create ${_pillarMeta[_selectedPillar]!['label']}",
                    style: theme.cardTitleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: theme.subtext),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_currentStep == 1) ...[
            Text("Choose which of the 4 Pillars you want to create:", style: theme.subtitleStyle.copyWith(fontSize: 12)),
            const SizedBox(height: 16),

            // 4 Pillar Selection List
            ..._pillarMeta.keys.map((key) {
              final meta = _pillarMeta[key]!;
              final Color color = meta["color"] as Color;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPillar = key;
                      _currentStep = 2;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(child: Text(meta["icon"] as String, style: const TextStyle(fontSize: 24))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meta["label"] as String, style: theme.cardTitleStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(meta["subtitle"] as String, style: theme.subtitleStyle.copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: color, size: 24),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ] else ...[
            // STEP 2: Tailored Form per Pillar
            if (_selectedPillar == "Stocks") _buildStockForm(theme),
            if (_selectedPillar == "Real-Estate") _buildRealEstateForm(theme),
            if (_selectedPillar == "Precious Metals") _buildPreciousMetalsForm(theme),
            if (_selectedPillar == "Health") _buildHealthForm(theme),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pillarMeta[_selectedPillar]!["color"] as Color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Create $_selectedPillar Asset", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Stock Profile Form
  Widget _buildStockForm(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _stockNameCtrl,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(
            labelText: "Stock Account / Portfolio Name (e.g. TFSA Growth)",
            labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
            filled: true,
            fillColor: theme.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _stockType,
                dropdownColor: theme.card,
                style: TextStyle(color: theme.text, fontSize: 13),
                decoration: InputDecoration(labelText: "Account Type", labelStyle: TextStyle(color: theme.subtext)),
                items: ["TFSA", "RRSP", "401(k)", "Taxable Brokerage", "Crypto Vault"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _stockType = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _stockCountry,
                dropdownColor: theme.card,
                style: TextStyle(color: theme.text, fontSize: 13),
                decoration: InputDecoration(labelText: "Jurisdiction", labelStyle: TextStyle(color: theme.subtext)),
                items: ["Canada", "United States", "Global"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _stockCountry = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Real Estate Property Form
  Widget _buildRealEstateForm(ThemeProvider theme) {
    return Column(
      children: [
        TextField(
          controller: _reNameCtrl,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(labelText: "Property Name (e.g., Waterfront Condo)", labelStyle: TextStyle(color: theme.subtext)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _reValCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Current Valuation (\$)", labelStyle: TextStyle(color: theme.subtext)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _reMortCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Mortgage Balance (\$)", labelStyle: TextStyle(color: theme.subtext)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _reRentCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Monthly Rent (\$)", labelStyle: TextStyle(color: theme.subtext)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _reExpCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Monthly Expenses (\$)", labelStyle: TextStyle(color: theme.subtext)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _reAddrCtrl,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(labelText: "Property Address / Location", labelStyle: TextStyle(color: theme.subtext)),
        ),
      ],
    );
  }

  // Precious Metals Form
  Widget _buildPreciousMetalsForm(ThemeProvider theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _pmMetalType,
                dropdownColor: theme.card,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Metal Type", labelStyle: TextStyle(color: theme.subtext)),
                items: ["Gold", "Silver", "Platinum", "Bronze"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _pmMetalType = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _pmWeightCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Weight (troy oz)", labelStyle: TextStyle(color: theme.subtext)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pmBuyPriceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Purchase Price / oz (\$)", labelStyle: TextStyle(color: theme.subtext)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _pmSpotPriceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Spot Price / oz (\$)", labelStyle: TextStyle(color: theme.subtext)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _pmLocCtrl,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(labelText: "Storage Location (e.g. Bank Vault)", labelStyle: TextStyle(color: theme.subtext)),
        ),
      ],
    );
  }

  // Health Form
  Widget _buildHealthForm(ThemeProvider theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _healthType,
                dropdownColor: theme.card,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Metric Type", labelStyle: TextStyle(color: theme.subtext)),
                items: ["Weight", "Resting Heart Rate", "Sleep Score", "Body Fat %"].map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                onChanged: (v) {
                  setState(() {
                    _healthType = v!;
                    if (v == "Weight") _healthUnit = "kg";
                    if (v == "Resting Heart Rate") _healthUnit = "bpm";
                    if (v == "Sleep Score") _healthUnit = "score";
                    if (v == "Body Fat %") _healthUnit = "%";
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _healthValCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Value ($_healthUnit)", labelStyle: TextStyle(color: theme.subtext)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _healthNotesCtrl,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(labelText: "Notes (Optional)", labelStyle: TextStyle(color: theme.subtext)),
        ),
      ],
    );
  }
}
