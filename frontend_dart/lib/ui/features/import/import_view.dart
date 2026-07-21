import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';

class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  final _formKey = GlobalKey<FormState>();

  String _profileId = "a9117be5-4ea5-419f-b778-be75b22b271d"; // TFSA ID default
  final _tickerController = TextEditingController(text: "TD");
  final _quantityController = TextEditingController(text: "20");
  final _priceController = TextEditingController(text: "81.50");
  String _currency = "CAD";
  final _brokerageController = TextEditingController(text: "Questrade");
  final _fxRateController = TextEditingController(text: "1.0");
  final _dateController = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );

  bool _isSubmitting = false;

  @override
  void dispose() {
    _tickerController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _brokerageController.dispose();
    _fxRateController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final success = await apiService.addTransaction(
        profileId: _profileId,
        ticker: _tickerController.text.trim(),
        quantity: double.parse(_quantityController.text.trim()),
        price: double.parse(_priceController.text.trim()),
        currency: _currency,
        brokerage: _brokerageController.text.trim(),
        fxRate: double.parse(_fxRateController.text.trim()),
        date: _dateController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Buy transaction successfully recorded!"),
            backgroundColor: AppColors.positive,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting transaction: ${e.toString()}"),
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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.bg,
        elevation: 0,
        leading: IconButton(
          icon: Text("←", style: TextStyle(color: theme.text, fontSize: 24, fontWeight: FontWeight.bold)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add Buy Transaction", style: theme.cardTitleStyle.copyWith(fontSize: 18)),
            Text("Import new stock holding allocations", style: theme.subtitleStyle),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Dropdown Selector
                    DropdownButtonFormField<String>(
                      initialValue: _profileId,
                      style: TextStyle(color: theme.text),
                      dropdownColor: theme.card,
                      decoration: InputDecoration(
                        labelText: "Target Investment Profile",
                        labelStyle: TextStyle(color: theme.subtext),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "a9117be5-4ea5-419f-b778-be75b22b271d",
                          child: Text("TFSA Account"),
                        ),
                        DropdownMenuItem(
                          value: "f90117d3-9bc0-4c28-98e3-4de75b2b271e",
                          child: Text("RRSP Ledger"),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _profileId = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Ticker symbol input
                    TextFormField(
                      controller: _tickerController,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(
                        labelText: "Ticker Symbol (e.g. AAPL, TD)",
                        labelStyle: TextStyle(color: theme.subtext),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? "Ticker is required" : null,
                    ),
                    const SizedBox(height: 20),

                    // Share quantity input
                    TextFormField(
                      controller: _quantityController,
                      style: TextStyle(color: theme.text),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Shares Amount",
                        labelStyle: TextStyle(color: theme.subtext),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Amount is required";
                        if (double.tryParse(val) == null) return "Enter a valid decimal";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Price per share input
                    TextFormField(
                      controller: _priceController,
                      style: TextStyle(color: theme.text),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Share Unit Price (Local Buying Currency)",
                        labelStyle: TextStyle(color: theme.subtext),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Price is required";
                        if (double.tryParse(val) == null) return "Enter a valid decimal";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Currency Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _currency,
                      style: TextStyle(color: theme.text),
                      dropdownColor: theme.card,
                      decoration: InputDecoration(
                        labelText: "Purchase Currency",
                        labelStyle: TextStyle(color: theme.subtext),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                      ),
                      items: const [
                        DropdownMenuItem(value: "CAD", child: Text("CAD (\$)")),
                        DropdownMenuItem(value: "USD", child: Text("USD (US\$)")),
                        DropdownMenuItem(value: "AUD", child: Text("AUD (A\$)")),
                        DropdownMenuItem(value: "GBP", child: Text("GBP (£)")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _currency = val;
                            // Set default FX rates
                            if (val == "CAD") {
                              _fxRateController.text = "1.0";
                            } else if (val == "USD") {
                              _fxRateController.text = "1.35";
                            } else if (val == "AUD") {
                              _fxRateController.text = "0.90";
                            } else if (val == "GBP") {
                              _fxRateController.text = "1.75";
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // FX Rate to CAD input
                    TextFormField(
                      controller: _fxRateController,
                      style: TextStyle(color: theme.text),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "FX Rate to CAD (1.0 for CAD)",
                        labelStyle: TextStyle(color: theme.subtext),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "FX Rate is required";
                        if (double.tryParse(val) == null) return "Enter a valid decimal";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Brokerage name input
                    TextFormField(
                      controller: _brokerageController,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(
                        labelText: "Brokerage Broker (Questrade, Wealthsimple)",
                        labelStyle: TextStyle(color: theme.subtext),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Purchase date input
                    TextFormField(
                      controller: _dateController,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(
                        labelText: "Purchase Date (YYYY-MM-DD)",
                        labelStyle: TextStyle(color: theme.subtext),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? "Date is required" : null,
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.positive,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Submit Buy Transaction",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
