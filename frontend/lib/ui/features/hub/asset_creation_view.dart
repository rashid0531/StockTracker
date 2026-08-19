import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../../core/providers/pillar_preferences_provider.dart';
import '../../core/theme.dart';

class AssetCreationView extends StatefulWidget {
  const AssetCreationView({super.key});

  @override
  State<AssetCreationView> createState() => _AssetCreationViewState();
}

class _AssetCreationViewState extends State<AssetCreationView> {
  final ApiService _apiService = ApiService();
  int _currentStep = 1; // 1: Choose Pillar, 2: Fill Asset Details
  String _selectedPillar = "Stocks";
  bool _isSubmitting = false;

  // Stocks Form Controllers
  final _stockNameCtrl = TextEditingController();
  String _stockType = "TFSA";
  String _stockCountry = "Canada";

  // Real Estate Form Controllers & State
  final _reNameCtrl = TextEditingController();
  final _reValCtrl = TextEditingController();
  final _reMortCtrl = TextEditingController();
  final _reRentCtrl = TextEditingController();
  final _reExpCtrl = TextEditingController();
  final _reAddrCtrl = TextEditingController();

  String _reRegion = "North America (NA)";
  String _rePropertyCategory = "Single-Family & Standalone Dwellings";
  String _reStructuralType = "Single-Family Detached (NA) / Detached House (UK/AU)";
  String _reTenureModel = "Freehold";
  bool _isPrimaryResidence = true;

  final List<String> _reRegions = [
    "North America (NA)",
    "UK / Europe (UK/EU)",
    "Australia / Oceania (AU)",
  ];

  final Map<String, List<Map<String, String>>> _reStructuralTaxonomy = {
    "Single-Family & Standalone Dwellings": [
      {
        "name": "Single-Family Detached (NA) / Detached House (UK/AU)",
        "desc": "Standalone single-dwelling building without shared structural walls."
      },
      {
        "name": "Bungalow",
        "desc": "Single-story or story-and-a-half house with a low-pitched roof."
      },
      {
        "name": "Villa (AU/UK)",
        "desc": "Single-story attached home in complex (AU) or holiday residence (UK/EU)."
      },
      {
        "name": "Cottage",
        "desc": "Small rustic single-family home or vacation property."
      },
      {
        "name": "Ranch / Single-Story House (NA)",
        "desc": "Wide single-story house with open-concept layout and attached garage."
      },
    ],
    "Attached & Semi-Attached Dwellings": [
      {
        "name": "Townhouse (NA/AU) / Terraced House (UK)",
        "desc": "Multi-story row house sharing side party walls on both sides."
      },
      {
        "name": "End-of-Terrace (UK) / End-Unit Townhouse (NA)",
        "desc": "Townhouse at end of row sharing a party wall on only one side."
      },
      {
        "name": "Semi-Detached House (UK/NA/AU) / Duplex (AU)",
        "desc": "Single building split vertically into two dwellings sharing central wall."
      },
      {
        "name": "Semi-Detached Duplex (NA)",
        "desc": "Single building with two self-contained units stacked vertically or side-by-side."
      },
      {
        "name": "Triplex / Quadplex (NA)",
        "desc": "Residential building divided into three or four separate living units."
      },
    ],
    "Multi-Family & High-Density Dwellings": [
      {
        "name": "Condominium (NA) / Strata Unit (AU) / Share of Freehold Flat (UK)",
        "desc": "Individually owned unit in larger building with shared common elements."
      },
      {
        "name": "Apartment / Flat (UK)",
        "desc": "Self-contained housing unit occupying part of a multi-unit building."
      },
      {
        "name": "Maisonette (UK/Europe)",
        "desc": "Multi-story apartment inside larger building with private exterior front door."
      },
      {
        "name": "Penthouse",
        "desc": "Premium luxury unit on top floor(s) of high-rise building."
      },
      {
        "name": "Studio Apartment / Bedsit (UK)",
        "desc": "Single-room living space integrating bedroom, living, and kitchen area."
      },
      {
        "name": "Micro-Apartment",
        "desc": "Ultra-compact apartment (<350 sq ft / 32 sqm) with space-saving features."
      },
    ],
    "Specialized & Alternate Dwellings": [
      {
        "name": "Accessory Dwelling Unit (ADU) / Granny Flat (AU/UK)",
        "desc": "Secondary smaller self-contained unit on same lot as primary home."
      },
      {
        "name": "Co-Living / House in Multiple Occupation (HMO - UK)",
        "desc": "Property where non-related tenants rent individual bedrooms with shared spaces."
      },
      {
        "name": "Loft",
        "desc": "Apartment converted from former commercial space with high ceilings."
      },
      {
        "name": "Manufactured / Mobile Home",
        "desc": "Prefabricated dwelling built off-site on permanent chassis."
      },
      {
        "name": "Floating Home / Houseboat",
        "desc": "Residential structure designed to float on water, permanently moored."
      },
    ],
    "Raw / Vacant Land": [
      {
        "name": "Raw / Vacant Land",
        "desc": "Unimproved raw land or buildable vacant lot."
      },
    ],
  };

  final List<String> _reTenureModels = [
    "Freehold",
    "Leasehold",
    "Condominium / Strata Title",
    "Share of Freehold",
    "Co-op / Housing Cooperative",
  ];

  // Precious Metals Form Controllers
  String _pmMetalType = "Gold";
  final String _pmForm = "1 oz Bar";
  final _pmWeightCtrl = TextEditingController();
  final _pmBuyPriceCtrl = TextEditingController();
  final _pmSpotPriceCtrl = TextEditingController();
  final _pmLocCtrl = TextEditingController(text: "Home Safe");

  // Health Form Controllers
  String _healthType = "Weight";
  final _healthValCtrl = TextEditingController();
  String _healthUnit = "kg";
  final _healthNotesCtrl = TextEditingController();

  final Map<String, Map<String, dynamic>> _pillarMeta = {
    "Stocks": {
      "icon": "📈",
      "color": AppColors.positive,
      "label": "Stocks & Equities",
      "subtitle": "Create TFSA, RRSP, 401(k), Taxable, or Crypto portfolio",
      "route": "/stocks",
    },
    "Real-Estate": {
      "icon": "🏠",
      "color": const Color(0xFF3B82F6),
      "label": "Real-Estate Property",
      "subtitle": "Add Single-Family, Townhouse, Condo, Maisonette, or Land",
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
          "property_type": _reStructuralType,
          "region": _reRegion,
          "property_category": _rePropertyCategory,
          "structural_type": _reStructuralType,
          "tenure_model": _reTenureModel,
          "purchase_price": double.tryParse(_reValCtrl.text) ?? 0.0,
          "current_value": double.tryParse(_reValCtrl.text) ?? 0.0,
          "mortgage_balance": double.tryParse(_reMortCtrl.text) ?? 0.0,
          "monthly_rent_income": double.tryParse(_reRentCtrl.text) ?? 0.0,
          "monthly_expenses": double.tryParse(_reExpCtrl.text) ?? 0.0,
          "address": _reAddrCtrl.text.trim(),
          "purchase_date": "2026-01-01",
          "is_primary_residence": _isPrimaryResidence,
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$_selectedPillar Asset Created Successfully! 🎉")),
      );
      router.replace(targetRoute);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
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
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/hub');
              }
            }
          },
        ),
        title: Text(
          _currentStep == 1 ? "Select Asset Category" : "Create ${_pillarMeta[_selectedPillar]!['label']}",
          style: theme.cardTitleStyle.copyWith(fontSize: 18),
        ),
      ),
      body: theme.buildBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 640),
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.border, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Indicator Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_pillarMeta[_selectedPillar]!["color"] as Color).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "STEP $_currentStep OF 2",
                            style: TextStyle(
                              color: _pillarMeta[_selectedPillar]!["color"] as Color,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_currentStep == 1) ...[
                      Text(
                        "What kind of asset do you want to create?",
                        style: theme.titleStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text("Select one of the 4 Pillars below to configure your asset profile.", style: theme.subtitleStyle),
                      const SizedBox(height: 24),

                      // Active Pillars Grid/List Selection Cards
                      ..._pillarMeta.keys
                          .where((key) => Provider.of<PillarPreferencesProvider>(context, listen: false).isPillarEnabled(key))
                          .map((key) {
                        final meta = _pillarMeta[key]!;
                        final Color color = meta["color"] as Color;
                        final bool isSelected = _selectedPillar == key;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPillar = key;
                                _currentStep = 2;
                              });
                            },
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withValues(alpha: 0.12) : theme.bg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: isSelected ? color : theme.border, width: isSelected ? 2 : 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(child: Text(meta["icon"] as String, style: const TextStyle(fontSize: 26))),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(meta["label"] as String, style: theme.cardTitleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(meta["subtitle"] as String, style: theme.subtitleStyle.copyWith(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ] else ...[
                      // STEP 2: Tailored Asset Form Page
                      Text(
                        "Configure ${_pillarMeta[_selectedPillar]!['label']}",
                        style: theme.titleStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text("Enter the details for your new asset profile.", style: theme.subtitleStyle),
                      const SizedBox(height: 24),

                      if (_selectedPillar == "Stocks") _buildStockForm(theme),
                      if (_selectedPillar == "Real-Estate") _buildRealEstateForm(theme),
                      if (_selectedPillar == "Precious Metals") _buildPreciousMetalsForm(theme),
                      if (_selectedPillar == "Health") _buildHealthForm(theme),

                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pillarMeta[_selectedPillar]!["color"] as Color,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          child: _isSubmitting
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Text("Create $_selectedPillar Asset", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Stocks Form
  Widget _buildStockForm(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _stockNameCtrl,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(
            labelText: "Portfolio / Account Name (e.g. TFSA Growth, RRSP)",
            labelStyle: TextStyle(color: theme.subtext, fontSize: 13),
            filled: true,
            fillColor: theme.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.border)),
          ),
        ),
        const SizedBox(height: 16),
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
            const SizedBox(width: 14),
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

  // Real Estate Form with Global Taxonomy & Tenure Models
  Widget _buildRealEstateForm(ThemeProvider theme) {
    final List<Map<String, String>> currentTypes = _reStructuralTaxonomy[_rePropertyCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Region Selector
        Text("1. Property Region / Market", style: theme.cardTitleStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _reRegions.map((r) {
            final isSelected = _reRegion == r;
            return ChoiceChip(
              label: Text(r, style: TextStyle(color: isSelected ? Colors.white : theme.text, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              selectedColor: const Color(0xFF3B82F6),
              backgroundColor: theme.bg,
              onSelected: (val) {
                if (val) setState(() => _reRegion = r);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // 2. Structural Category Dropdown
        Text("2. Structural Category", style: theme.cardTitleStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _rePropertyCategory,
          dropdownColor: theme.card,
          style: TextStyle(color: theme.text, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
          ),
          items: _reStructuralTaxonomy.keys.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _rePropertyCategory = v;
                _reStructuralType = _reStructuralTaxonomy[v]!.first["name"]!;
              });
            }
          },
        ),
        const SizedBox(height: 18),

        // 3. Structural Type Selector
        Text("3. Structural Type", style: theme.cardTitleStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            children: currentTypes.map((t) {
              final isSelected = _reStructuralType == t["name"];
              return InkWell(
                onTap: () {
                  setState(() => _reStructuralType = t["name"]!);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? const Color(0xFF3B82F6) : theme.subtext,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t["name"]!, style: theme.cardTitleStyle.copyWith(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            const SizedBox(height: 2),
                            Text(t["desc"]!, style: theme.subtitleStyle.copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),

        // 4. Tenure & Ownership Model
        Text("4. Tenure & Ownership Model", style: theme.cardTitleStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _reTenureModel,
          dropdownColor: theme.card,
          style: TextStyle(color: theme.text, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
          ),
          items: _reTenureModels.map((tm) => DropdownMenuItem(value: tm, child: Text(tm))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _reTenureModel = v);
          },
        ),
        const SizedBox(height: 18),

        // 5. Property Name & Financial Details
        Text("5. Financial Valuation & Details", style: theme.cardTitleStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _reNameCtrl,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(
            labelText: "Property Name (e.g. Waterfront Penthouse, London Terrace)",
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
              child: TextField(
                controller: _reValCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(
                  labelText: "Current Valuation (\$)",
                  labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
                  filled: true,
                  fillColor: theme.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _reMortCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(
                  labelText: "Mortgage Balance (\$)",
                  labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
                  filled: true,
                  fillColor: theme.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _reRentCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(
                  labelText: "Monthly Rent (\$)",
                  labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
                  filled: true,
                  fillColor: theme.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _reExpCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(
                  labelText: "Monthly Expenses (\$)",
                  labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
                  filled: true,
                  fillColor: theme.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _reAddrCtrl,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(
            labelText: "Property Address / Location",
            labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
            filled: true,
            fillColor: theme.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
          ),
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            title: Text("Primary Residence", style: TextStyle(color: theme.text, fontSize: 14)),
            subtitle: Text("Turn off if this is an Investment Property", style: TextStyle(color: theme.subtext, fontSize: 12)),
            value: _isPrimaryResidence,
            activeTrackColor: AppColors.positive.withValues(alpha: 0.5),
            activeThumbColor: AppColors.positive,
            contentPadding: EdgeInsets.zero,
            onChanged: (bool value) {
              setState(() {
                _isPrimaryResidence = value;
              });
            },
          ),
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
            const SizedBox(width: 14),
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
        const SizedBox(height: 14),
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
            const SizedBox(width: 14),
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
        const SizedBox(height: 14),
        TextField(
          controller: _pmLocCtrl,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(labelText: "Storage Location (e.g. Bank Safe)", labelStyle: TextStyle(color: theme.subtext)),
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
            const SizedBox(width: 14),
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
        const SizedBox(height: 14),
        TextField(
          controller: _healthNotesCtrl,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(labelText: "Notes (Optional)", labelStyle: TextStyle(color: theme.subtext)),
        ),
      ],
    );
  }
}
