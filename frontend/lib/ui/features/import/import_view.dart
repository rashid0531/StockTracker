import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/profile.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';

class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  int _currentStep = 1; // 1: Country & Currency, 2: Profile Setup, 3: Add Stocks, 4: Success

  // Step 1 State: Primary Residence & Base Currency
  String _selectedPrimaryCountry = "Canada";
  String _selectedPrimaryCurrency = "CAD";

  // Step 2 State: Profile Details
  final _profileNameController = TextEditingController(text: "My Growth Portfolio");
  late String _selectedProfileCountry;
  late String _selectedAccountType;

  // Step 3 State: Stock Positions Entry
  final _formKey = GlobalKey<FormState>();
  final _tickerController = TextEditingController(text: "TD");
  final _nameController = TextEditingController(text: "Toronto-Dominion Bank");
  final _quantityController = TextEditingController(text: "25");
  final _priceController = TextEditingController(text: "81.50");
  String _stockCurrency = "CAD";
  final _brokerageController = TextEditingController(text: "Questrade");
  final _dateController = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );

  final List<Map<String, dynamic>> _stagedPositions = [];
  bool _isSubmitting = false;
  InvestmentProfile? _createdProfile;

  final List<String> _countryList = [
    "Canada",
    "United States",
    "United Kingdom",
    "Australia",
    "Germany",
    "Global / Other"
  ];

  final List<String> _currencyList = [
    "CAD",
    "USD",
    "GBP",
    "AUD",
    "EUR"
  ];

  @override
  void initState() {
    super.initState();
    _selectedProfileCountry = _selectedPrimaryCountry;
    _updateAccountTypesForCountry(_selectedProfileCountry);
  }

  void _updateAccountTypesForCountry(String country) {
    final types = ApiService.countryAccountTypes[country] ?? ApiService.countryAccountTypes["Global / Other"]!;
    setState(() {
      _selectedProfileCountry = country;
      _selectedAccountType = types.first;
    });
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    _tickerController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _brokerageController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _addStagedPosition() {
    if (!_formKey.currentState!.validate()) return;

    final ticker = _tickerController.text.trim().toUpperCase();
    final name = _nameController.text.trim().isEmpty ? ticker : _nameController.text.trim();
    final shares = double.parse(_quantityController.text.trim());
    final price = double.parse(_priceController.text.trim());

    setState(() {
      _stagedPositions.add({
        "ticker": ticker,
        "name": name,
        "shares": shares,
        "price": price,
        "currency": _stockCurrency,
        "brokerage": _brokerageController.text.trim(),
        "date": _dateController.text.trim(),
      });

      // Clear fields for next entry
      _tickerController.clear();
      _nameController.clear();
      _quantityController.clear();
      _priceController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Position $ticker added to import queue!"),
        backgroundColor: AppColors.positive,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitAllProfileAndStocks() async {
    // If form fields contain valid text, stage them automatically first
    if (_tickerController.text.trim().isNotEmpty && _quantityController.text.trim().isNotEmpty && _priceController.text.trim().isNotEmpty) {
      if (_formKey.currentState!.validate()) {
        _addStagedPosition();
      }
    }

    if (_stagedPositions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one stock position to create the profile."),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      // 1. Save primary residence & currency preferences
      apiService.setUserPrimaryPreferences(
        country: _selectedPrimaryCountry,
        currency: _selectedPrimaryCurrency,
      );

      // 2. Create investment profile attached to specified country & account type
      final profile = await apiService.createProfile(
        name: _profileNameController.text.trim().isEmpty
            ? "$_selectedProfileCountry $_selectedAccountType"
            : _profileNameController.text.trim(),
        country: _selectedProfileCountry,
        type: _selectedAccountType,
      );

      // 3. Add all staged stock holdings to new profile
      for (var pos in _stagedPositions) {
        final double fxRate = pos["currency"] == "CAD" ? 1.0 : (pos["currency"] == "USD" ? 1.35 : 1.0);
        await apiService.addTransaction(
          profileId: profile.id,
          ticker: pos["ticker"],
          quantity: pos["shares"],
          price: pos["price"],
          currency: pos["currency"],
          brokerage: pos["brokerage"].isEmpty ? "Primary Brokerage" : pos["brokerage"],
          fxRate: fxRate,
          date: pos["date"],
        );
      }

      setState(() {
        _createdProfile = profile;
        _currentStep = 4; // Move to completion step
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error creating profile: ${e.toString()}"),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForNextProfile() {
    setState(() {
      _currentStep = 2; // Jump directly to Step 2 to add another profile
      _stagedPositions.clear();
      _profileNameController.text = "Second Investment Account";
      _tickerController.clear();
      _nameController.clear();
      _quantityController.clear();
      _priceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.text),
          onPressed: () {
            if (_currentStep > 1 && _currentStep < 4) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentStep == 4 ? "Profile Created!" : "Profile Setup & Stock Import",
              style: theme.cardTitleStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            Text(
              _currentStep == 1
                  ? "Step 1 of 3: Residence & Currency"
                  : _currentStep == 2
                      ? "Step 2 of 3: Account Setup"
                      : _currentStep == 3
                          ? "Step 3 of 3: Import Stock Holdings"
                          : "Setup Complete",
              style: theme.subtitleStyle.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
      body: theme.buildBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Wizard Progress Bar (for steps 1-3)
              if (_currentStep <= 3) ...[
                Row(
                  children: [
                    _buildStepIndicator(1, "Residence", theme),
                    _buildStepLine(1, theme),
                    _buildStepIndicator(2, "Account", theme),
                    _buildStepLine(2, theme),
                    _buildStepIndicator(3, "Stocks", theme),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // STEP 1: Country & Currency Setup
              if (_currentStep == 1) _buildStep1(theme),

              // STEP 2: Profile Details & Account Type
              if (_currentStep == 2) _buildStep2(theme),

              // STEP 3: Stock Position Entry
              if (_currentStep == 3) _buildStep3(theme),

              // STEP 4: Success & Multi-Profile Prompt
              if (_currentStep == 4) _buildStep4(theme),
            ],
          ),
        ),
      ),
    );
  }

  // Step Progress Indicator Pill
  Widget _buildStepIndicator(int stepNum, String label, ThemeProvider theme) {
    final isActive = _currentStep == stepNum;
    final isDone = _currentStep > stepNum;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone || isActive ? AppColors.positive : theme.card,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive || isDone ? AppColors.positive : theme.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      "$stepNum",
                      style: TextStyle(
                        color: isActive ? Colors.white : theme.subtext,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? theme.text : theme.subtext,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int stepNum, ThemeProvider theme) {
    final isDone = _currentStep > stepNum;
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDone ? AppColors.positive : theme.border,
    );
  }

  // STEP 1: Primary Country & Base Currency Card
  Widget _buildStep1(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.positive.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text("🌍", style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Primary Country & Base Currency", style: theme.cardTitleStyle.copyWith(fontSize: 16)),
                    Text("Used as default for portfolio reporting", style: theme.subtitleStyle.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Country Selector
          DropdownButtonFormField<String>(
            initialValue: _selectedPrimaryCountry,
            style: TextStyle(color: theme.text),
            dropdownColor: theme.card,
            decoration: InputDecoration(
              labelText: "Primary Country of Residence",
              labelStyle: TextStyle(color: theme.subtext),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.positive)),
            ),
            items: _countryList.map((country) {
              return DropdownMenuItem(
                value: country,
                child: Text(country),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedPrimaryCountry = val;
                  _updateAccountTypesForCountry(val);
                });
              }
            },
          ),
          const SizedBox(height: 20),

          // Currency Selector
          DropdownButtonFormField<String>(
            initialValue: _selectedPrimaryCurrency,
            style: TextStyle(color: theme.text),
            dropdownColor: theme.card,
            decoration: InputDecoration(
              labelText: "Default Base Reporting Currency",
              labelStyle: TextStyle(color: theme.subtext),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.positive)),
            ),
            items: _currencyList.map((curr) {
              return DropdownMenuItem(
                value: curr,
                child: Text("$curr (${curr == 'CAD' || curr == 'USD' || curr == 'AUD' ? '\$' : (curr == 'GBP' ? '£' : '€')})"),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedPrimaryCurrency = val);
              }
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              setState(() => _currentStep = 2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.positive,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Continue to Profile Setup", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Profile Name & Country-Specific Account Types Card
  Widget _buildStep2(ThemeProvider theme) {
    final availableTypes = ApiService.countryAccountTypes[_selectedProfileCountry] ??
        ApiService.countryAccountTypes["Global / Other"]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.positive.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text("🏦", style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Create Investment Profile", style: theme.cardTitleStyle.copyWith(fontSize: 16)),
                    Text("Configure account type for tax calculation", style: theme.subtitleStyle.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Profile Name
          TextField(
            controller: _profileNameController,
            style: TextStyle(color: theme.text),
            decoration: InputDecoration(
              labelText: "Profile Nickname (e.g. My TFSA Growth, Roth IRA)",
              labelStyle: TextStyle(color: theme.subtext),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.positive)),
            ),
          ),
          const SizedBox(height: 20),

          // Profile Country Selector
          DropdownButtonFormField<String>(
            initialValue: _selectedProfileCountry,
            style: TextStyle(color: theme.text),
            dropdownColor: theme.card,
            decoration: InputDecoration(
              labelText: "Profile Jurisdiction / Country",
              labelStyle: TextStyle(color: theme.subtext),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.positive)),
            ),
            items: _countryList.map((country) {
              return DropdownMenuItem(value: country, child: Text(country));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                _updateAccountTypesForCountry(val);
              }
            },
          ),
          const SizedBox(height: 20),

          // Dynamic Account Type Dropdown (populates based on country!)
          DropdownButtonFormField<String>(
            initialValue: availableTypes.contains(_selectedAccountType) ? _selectedAccountType : availableTypes.first,
            style: TextStyle(color: theme.text),
            dropdownColor: theme.card,
            decoration: InputDecoration(
              labelText: "Account Type ($_selectedProfileCountry Rules)",
              labelStyle: TextStyle(color: theme.subtext),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.positive)),
            ),
            items: availableTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedAccountType = val);
              }
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.isDark ? const Color(0xFF1B202A) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Tax calculations and allowances for $_selectedProfileCountry ($_selectedAccountType) will be calculated automatically.",
                    style: theme.subtitleStyle.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              setState(() => _currentStep = 3);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.positive,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Next: Add Stock Holdings", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Stock Positions Entry Form Card & Staged List
  Widget _buildStep3(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.border, width: 1.5),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.positive.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text("📊", style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Import Stock Position", style: theme.cardTitleStyle.copyWith(fontSize: 16)),
                          Text("Target: ${_profileNameController.text} ($_selectedAccountType)", style: theme.subtitleStyle.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Ticker Symbol Input
                TextFormField(
                  controller: _tickerController,
                  style: TextStyle(color: theme.text),
                  decoration: InputDecoration(
                    labelText: "Stock Ticker Symbol (e.g. AAPL, TD, XIU)",
                    labelStyle: TextStyle(color: theme.subtext),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.positive)),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) && _stagedPositions.isEmpty
                      ? "Ticker symbol is required"
                      : null,
                ),
                const SizedBox(height: 16),

                // Stock Name Input
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: theme.text),
                  decoration: InputDecoration(
                    labelText: "Company Name (Optional)",
                    labelStyle: TextStyle(color: theme.subtext),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.positive)),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        style: TextStyle(color: theme.text),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Number of Shares",
                          labelStyle: TextStyle(color: theme.subtext),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.positive)),
                        ),
                        validator: (val) {
                          if ((val == null || val.isEmpty) && _stagedPositions.isEmpty) return "Shares required";
                          if (val != null && val.isNotEmpty && double.tryParse(val) == null) return "Invalid decimal";
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        style: TextStyle(color: theme.text),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Purchase Unit Price",
                          labelStyle: TextStyle(color: theme.subtext),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.positive)),
                        ),
                        validator: (val) {
                          if ((val == null || val.isEmpty) && _stagedPositions.isEmpty) return "Price required";
                          if (val != null && val.isNotEmpty && double.tryParse(val) == null) return "Invalid decimal";
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _stockCurrency,
                        style: TextStyle(color: theme.text),
                        dropdownColor: theme.card,
                        decoration: InputDecoration(
                          labelText: "Stock Currency",
                          labelStyle: TextStyle(color: theme.subtext),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                        ),
                        items: _currencyList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _stockCurrency = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        style: TextStyle(color: theme.text),
                        decoration: InputDecoration(
                          labelText: "Import Date (YYYY-MM-DD)",
                          labelStyle: TextStyle(color: theme.subtext),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Button to stage position
                OutlinedButton.icon(
                  onPressed: _addStagedPosition,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.positive, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.positive, size: 18),
                  label: const Text(
                    "Add Position to Queue",
                    style: TextStyle(color: AppColors.positive, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Staged Positions List
        if (_stagedPositions.isNotEmpty) ...[
          Text("Staged Positions (${_stagedPositions.length})", style: theme.cardTitleStyle.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          ..._stagedPositions.asMap().entries.map((entry) {
            final idx = entry.key;
            final pos = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.positive.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        pos["ticker"],
                        style: const TextStyle(color: AppColors.positive, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${pos['ticker']} - ${pos['name']}", style: theme.cardTitleStyle.copyWith(fontSize: 13)),
                        Text("${pos['shares']} shares • \$${pos['price']} ${pos['currency']}", style: theme.subtitleStyle.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                    onPressed: () {
                      setState(() {
                        _stagedPositions.removeAt(idx);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Final Submit Button
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitAllProfileAndStocks,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.positive,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  _stagedPositions.isEmpty ? "Save Profile & Holdings" : "Save Profile & ${_stagedPositions.length} Positions",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),
      ],
    );
  }

  // STEP 4: Success & Multi-Profile Support
  Widget _buildStep4(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.positive.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.positive, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.check_circle_rounded, color: AppColors.positive, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Profile Created!",
            style: theme.titleStyle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            "Your investment profile and stock holdings have been imported.",
            style: theme.subtitleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Created Profile Summary Card
          if (_createdProfile != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.isDark ? const Color(0xFF1E222A) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_createdProfile!.name, style: theme.cardTitleStyle.copyWith(fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.positive.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _createdProfile!.type,
                          style: const TextStyle(color: AppColors.positive, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Jurisdiction Country:", style: theme.subtitleStyle.copyWith(fontSize: 12)),
                      Text(_createdProfile!.country ?? _selectedProfileCountry, style: theme.cardTitleStyle.copyWith(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Imported Positions:", style: theme.subtitleStyle.copyWith(fontSize: 12)),
                      Text("${_stagedPositions.length} Holdings", style: theme.cardTitleStyle.copyWith(fontSize: 12, color: AppColors.positive)),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),

          // Multi-Profile Actions
          ElevatedButton.icon(
            onPressed: _resetForNextProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.positive,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              "Create Another Profile (e.g. RRSP, Roth IRA)",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go("/dashboard"),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: theme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              "Go to Dashboard",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.text),
            ),
          ),
        ],
      ),
    );
  }
}
