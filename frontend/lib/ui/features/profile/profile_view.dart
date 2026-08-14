import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/profile.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';

// Top-level mock sector list helper
Map<String, dynamic> _getStockMetadata(String ticker) {
  final t = ticker.toUpperCase().trim();
  if (t.contains("AAPL") || t.contains("MSFT") || t.contains("TSLA")) {
    return {"sector": "Technology", "dividendYield": 0.005};
  }
  if (t.contains("XIU") || t.contains("RY") || t.contains("TD") || t.contains("BNS")) {
    return {"sector": "Financials", "dividendYield": 0.032};
  }
  if (t.contains("BHP") || t.contains("RIO") || t.contains("VALE")) {
    return {"sector": "Materials", "dividendYield": 0.052};
  }
  if (t.contains("BP") || t.contains("XOM") || t.contains("CVX") || t.contains("ENB")) {
    return {"sector": "Energy", "dividendYield": 0.046};
  }
  return {"sector": "Other", "dividendYield": 0.020};
}

class ProfileViewModel extends ChangeNotifier {
  final ApiService apiService;
  final String profileId;

  InvestmentProfile? _profile;
  List<ChartPoint> _chartPoints = [];
  bool _isLoading = true;
  String _activeInterval = "1Y";
  String _chartMode = "VALUATION"; // "VALUATION" | "DIVIDEND"
  String _activeTab = "ANALYTICS"; // "ANALYTICS" | "SUGGESTIONS"

  ProfileViewModel({required this.apiService, required this.profileId});

  InvestmentProfile? get profile => _profile;
  List<ChartPoint> get chartPoints => _chartPoints;
  bool get isLoading => _isLoading;
  String get activeInterval => _activeInterval;
  String get chartMode => _chartMode;
  String get activeTab => _activeTab;

  void setChartMode(String mode) {
    _chartMode = mode;
    loadHistoryChart();
  }

  void setActiveInterval(String interval) {
    _activeInterval = interval;
    loadHistoryChart();
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  Future<void> loadProfileDetails() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await apiService.getProfileDetail(profileId);
      await loadHistoryChart(notify: false);
    } catch (e) {
      debugPrint("Error loading profile details: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistoryChart({bool notify = true}) async {
    try {
      _chartPoints = await apiService.getChartPoints(
        profileId,
        _activeInterval,
        _chartMode == "DIVIDEND",
      );
      if (notify) notifyListeners();
    } catch (e) {
      debugPrint("Error loading history chart: $e");
    }
  }

  // Pre-calculate Donut Chart Datasets
  List<DonutChartItem> get stockAllocItems {
    if (_profile == null) return [];
    double total = _profile!.stocks.fold(0, (acc, s) => acc + apiService.convertCurrencyToCAD(s.value, s.currency));
    if (total == 0) return [];

    final list = _profile!.stocks.map((s) {
      final valCAD = apiService.convertCurrencyToCAD(s.value, s.currency);
      return DonutChartItem(
        key: s.ticker,
        label: s.ticker,
        value: valCAD,
        percentage: valCAD / total,
      );
    }).toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  List<DonutChartItem> get sectorAllocItems {
    if (_profile == null) return [];
    final Map<String, double> sectors = {};
    for (var s in _profile!.stocks) {
      final meta = _getStockMetadata(s.ticker);
      final valCAD = apiService.convertCurrencyToCAD(s.value, s.currency);
      final sector = meta["sector"] as String;
      sectors[sector] = (sectors[sector] ?? 0.0) + valCAD;
    }

    double total = sectors.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return [];

    final list = sectors.keys.map((sector) {
      return DonutChartItem(
        key: sector,
        label: sector,
        value: sectors[sector]!,
        percentage: sectors[sector]! / total,
      );
    }).toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  List<DonutChartItem> get dividendContribItems {
    if (_profile == null) return [];
    final contributions = _profile!.stocks.map((s) {
      final meta = _getStockMetadata(s.ticker);
      final valCAD = apiService.convertCurrencyToCAD(s.value, s.currency);
      final divYield = meta["dividendYield"] as double;
      final divAnnual = valCAD * divYield;
      return {
        "ticker": s.ticker,
        "divAnnual": divAnnual,
      };
    }).toList();

    double total = contributions.fold(0.0, (acc, val) => acc + (val["divAnnual"] as double));
    if (total == 0) return [];

    final list = contributions.map((c) {
      final ticker = c["ticker"] as String;
      final divVal = c["divAnnual"] as double;
      return DonutChartItem(
        key: ticker,
        label: ticker,
        value: divVal,
        percentage: divVal / total,
      );
    }).toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}

class DonutChartItem {
  final String key;
  final String label;
  final double value;
  final double percentage;
  late Color color;

  DonutChartItem({
    required this.key,
    required this.label,
    required this.value,
    required this.percentage,
  });
}

final List<Color> _donutColors = [
  const Color(0xFF4CAF50),
  const Color(0xFF2196F3),
  const Color(0xFF9C27B0),
  const Color(0xFFFF9800),
  const Color(0xFFE91E63),
  const Color(0xFF00BCD4),
  const Color(0xFF8BC34A),
  const Color(0xFF3F51B5),
];

class ProfileView extends StatefulWidget {
  final String profileId;
  const ProfileView({super.key, required this.profileId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel(apiService: ApiService(), profileId: widget.profileId);
    Future.microtask(() => _viewModel.loadProfileDetails());
  }

  String formatCurrency(double amount, String currency) {
    if (currency == "CAD") return "\$${amount.toStringAsFixed(2)}";
    if (currency == "USD") return "US\$${amount.toStringAsFixed(2)}";
    if (currency == "AUD") return "A\$${amount.toStringAsFixed(2)}";
    if (currency == "GBP") return "£${amount.toStringAsFixed(2)}";
    return "\$${amount.toStringAsFixed(2)}";
  }

  void _showThesisJournalSheet(BuildContext context, StockHolding stock, ThemeProvider theme) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final thesisController = TextEditingController();
    int reviewInterval = 180;
    bool isSaving = false;
    bool isLoadingThesis = true;
    StockThesis? existingThesis;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isLoadingThesis) {
              isLoadingThesis = false;
              apiService.getStockThesis(ApiService.mockUserId, stock.stockId).then((thesis) {
                if (thesis != null) {
                  setModalState(() {
                    existingThesis = thesis;
                    thesisController.text = thesis.thesisText;
                    reviewInterval = thesis.reviewIntervalDays;
                  });
                }
              }).catchError((err) {
                debugPrint("Error loading thesis: $err");
              });
            }

            final needsReview = existingThesis == null || existingThesis!.needsReview || thesisController.text.isEmpty;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stock.ticker, style: theme.titleStyle.copyWith(fontSize: 20)),
                            Text(stock.name, style: theme.subtitleStyle),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.border),
                          ),
                          child: Text(
                            "${stock.shares} shares",
                            style: TextStyle(color: theme.text, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: theme.border),
                    const SizedBox(height: 12),
                    if (needsReview)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.28)),
                        ),
                        child: Row(
                          children: [
                            const Text("⚠️", style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                existingThesis == null 
                                    ? "No investment thesis recorded. Nudge to write down your thesis!"
                                    : "Outdated or Empty: Review and refine your original investment thesis.",
                                style: TextStyle(color: const Color(0xFFFFB300), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text("Investment Thesis", style: theme.cardTitleStyle.copyWith(fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      "Document your reasoning for holding this asset to avoid emotional decisions during market volatility.",
                      style: theme.subtitleStyle,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: thesisController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Why do you own this stock? (e.g., solid cash flow, strong tailwinds, moat, etc.)",
                        hintStyle: TextStyle(color: theme.subtext.withValues(alpha: 0.6)),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.positive),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.border),
                        ),
                      ),
                      style: TextStyle(color: theme.text, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Review Interval", style: theme.cardTitleStyle.copyWith(fontSize: 13)),
                        DropdownButton<int>(
                          value: reviewInterval,
                          dropdownColor: theme.card,
                          style: TextStyle(color: theme.text, fontSize: 13, fontWeight: FontWeight.bold),
                          underline: Container(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                reviewInterval = val;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 90, child: Text("90 Days")),
                            DropdownMenuItem(value: 180, child: Text("180 Days")),
                            DropdownMenuItem(value: 360, child: Text("360 Days")),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                try {
                                  await apiService.saveStockThesis(
                                    ApiService.mockUserId,
                                    stock.stockId,
                                    thesisController.text,
                                    reviewInterval,
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  debugPrint("Error saving thesis: $e");
                                } finally {
                                  setModalState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.positive,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Save Thesis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.bg,
      body: theme.buildBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.positive),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Header Row with back and home buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.card,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.border),
                                ),
                                child: Text("←", style: TextStyle(color: theme.text, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_viewModel.profile?.name ?? "Details", style: theme.titleStyle.copyWith(fontSize: 18)),
                                Text("Portfolio Breakdown & History", style: theme.subtitleStyle),
                              ],
                            ),
                          ],
                        ),
                        // Home icon button
                        IconButton(
                          onPressed: () => context.go("/dashboard"),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.border),
                            ),
                            child: Text("🏠", style: TextStyle(color: theme.text, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Content
                  Expanded(
                    child: _buildPerformanceTab(theme),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

  Widget _buildPerformanceTab(ThemeProvider theme) {
    final stocks = _viewModel.profile?.stocks ?? [];
    
    final stockItems = _viewModel.stockAllocItems;
    final sectorItems = _viewModel.sectorAllocItems;
    final divItems = _viewModel.dividendContribItems;

    // Apply colors to items
    for (int i = 0; i < stockItems.length; i++) {
      stockItems[i].color = _donutColors[i % _donutColors.length];
    }
    for (int i = 0; i < sectorItems.length; i++) {
      sectorItems[i].color = _donutColors[(i + 2) % _donutColors.length];
    }
    for (int i = 0; i < divItems.length; i++) {
      divItems[i].color = _donutColors[(i + 4) % _donutColors.length];
    }

    return ListView(
      children: [
        // Touch Interactive History Line Chart
        InteractiveHistoryChart(points: _viewModel.chartPoints),
        const SizedBox(height: 16),

        // Interval scrollselector
        _buildIntervalSelector(theme),
        const SizedBox(height: 24),

        // Action Buttons
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  "Analytics",
                  () => context.push('/profile/${widget.profileId}/analytics'),
                  false,
                  theme,
                ),
              ),
              Expanded(
                child: _buildActionButton(
                  "Suggestions",
                  () => context.push('/profile/${widget.profileId}/suggestions'),
                  false,
                  theme,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Holdings listings header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Active Allocations",
              style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
            InkWell(
              onTap: () => _showBuySellModal(context, type: "BUY", theme: theme),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.positive.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.positive, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: AppColors.positive, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "Add Stock",
                      style: TextStyle(color: AppColors.positive, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (stocks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: Text("No active stock allocations", style: TextStyle(color: Colors.grey))),
          )
        else
          ...stocks.map((stock) {
            final isPositive = stock.change >= 0;
            return InkWell(
              onTap: () => _showThesisJournalSheet(context, stock, theme),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    // Ticker icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.isDark ? const Color(0xFF1E2126) : const Color(0xFFF9FAFB),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.border),
                      ),
                      child: Center(
                        child: Text(
                          stock.ticker.substring(0, math.min(2, stock.ticker.length)).toUpperCase(),
                          style: TextStyle(color: theme.text, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Ticker text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(stock.ticker, style: theme.cardTitleStyle.copyWith(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text("📝", style: TextStyle(fontSize: 12, color: theme.subtext.withValues(alpha: 0.6))),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(stock.name, style: theme.subtitleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Action buttons: Buy (+) and Sell (-)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _showBuySellModal(context, stock: stock, type: "BUY", theme: theme),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.positive.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.positive, width: 1),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, color: AppColors.positive, size: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _showBuySellModal(context, stock: stock, type: "SELL", theme: theme),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.negative.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.negative, width: 1),
                            ),
                            child: const Center(
                              child: Icon(Icons.remove, color: AppColors.negative, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    // Middle shares details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock.shares.toString(), style: theme.cardTitleStyle.copyWith(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text("shares", style: theme.subtitleStyle),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Right: Price & subtotal valuation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatCurrency(stock.price, stock.currency), style: theme.cardTitleStyle.copyWith(fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isPositive ? AppColors.positive : AppColors.negative).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${isPositive ? "+" : ""}${stock.changePercent.toStringAsFixed(2)}%",
                            style: TextStyle(
                              color: isPositive ? AppColors.positive : AppColors.negative,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap, bool isActive, ThemeProvider theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.positive.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.positive : theme.subtext,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showBuySellModal(
    BuildContext context, {
    StockHolding? stock,
    required String type, // "BUY" | "SELL"
    required ThemeProvider theme,
  }) {
    final isBuy = type.toUpperCase() == "BUY";
    final sharesController = TextEditingController(text: "1.0");
    final priceController = TextEditingController(text: stock != null ? stock.price.toStringAsFixed(2) : "100.00");
    final tickerController = TextEditingController(text: stock?.ticker ?? "");
    final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: theme.border, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isBuy ? AppColors.positive : AppColors.negative).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isBuy ? "+ BUY SHARES" : "- SELL SHARES",
                            style: TextStyle(
                              color: isBuy ? AppColors.positive : AppColors.negative,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          stock != null ? stock.ticker : "New Transaction",
                          style: theme.cardTitleStyle.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(modalContext),
                      icon: Icon(Icons.close, color: theme.subtext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (stock == null) ...[
                  Text("Ticker Symbol", style: theme.subtitleStyle),
                  const SizedBox(height: 6),
                  TextField(
                    controller: tickerController,
                    style: TextStyle(color: theme.text),
                    decoration: InputDecoration(
                      hintText: "e.g. AAPL, XIU",
                      hintStyle: TextStyle(color: theme.subtext),
                      filled: true,
                      fillColor: theme.isDark ? const Color(0xFF191C21) : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text("Number of Shares", style: theme.subtitleStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: sharesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: theme.text),
                  decoration: InputDecoration(
                    hintText: "e.g. 10.0",
                    hintStyle: TextStyle(color: theme.subtext),
                    filled: true,
                    fillColor: theme.isDark ? const Color(0xFF191C21) : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Text("Price per Share", style: theme.subtitleStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: theme.text),
                  decoration: InputDecoration(
                    prefixText: stock != null ? "${stock.currency} \$ " : "\$ ",
                    prefixStyle: TextStyle(color: theme.text, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: theme.isDark ? const Color(0xFF191C21) : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Text("Transaction Date", style: theme.subtitleStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: dateController,
                  style: TextStyle(color: theme.text),
                  decoration: InputDecoration(
                    hintText: "YYYY-MM-DD",
                    hintStyle: TextStyle(color: theme.subtext),
                    filled: true,
                    fillColor: theme.isDark ? const Color(0xFF191C21) : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final ticker = (stock?.ticker ?? tickerController.text).trim();
                      final shares = double.tryParse(sharesController.text) ?? 0.0;
                      final price = double.tryParse(priceController.text) ?? 0.0;

                      if (ticker.isEmpty || shares <= 0 || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter valid ticker, shares, and price")),
                        );
                        return;
                      }

                      final profileId = _viewModel.profileId;
                      final currency = stock?.currency ?? "USD";

                      Navigator.pop(modalContext);

                      final success = await ApiService().executeBuySellTransaction(
                        profileId: profileId,
                        ticker: ticker,
                        type: type,
                        shares: shares,
                        price: price,
                        currency: currency,
                        date: dateController.text,
                      );

                      if (success) {
                        await _viewModel.loadProfileDetails();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${type.toUpperCase()} transaction executed for $ticker!"),
                              backgroundColor: isBuy ? AppColors.positive : AppColors.negative,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBuy ? AppColors.positive : AppColors.negative,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      "Confirm ${type.toUpperCase()}",
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeToggle(ThemeProvider theme, {bool subtitleText = false}) {
    final isValuation = _viewModel.chartMode == "VALUATION";

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _viewModel.setChartMode("VALUATION"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isValuation ? AppColors.positive : Colors.transparent,
                foregroundColor: isValuation ? Colors.white : theme.subtext,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                subtitleText ? "Valuation Breakdown" : "Valuation",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _viewModel.setChartMode("DIVIDEND"),
              style: ElevatedButton.styleFrom(
                backgroundColor: !isValuation ? AppColors.dividend : Colors.transparent,
                foregroundColor: !isValuation ? Colors.white : theme.subtext,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                subtitleText ? "Dividend Contribution" : "Dividend Income",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalSelector(ThemeProvider theme) {
    final intervals = ["1W", "6M", "1Y", "ALL"];
    final isValuation = _viewModel.chartMode == "VALUATION";

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Row(
        children: intervals.map((interval) {
          final isActive = _viewModel.activeInterval == interval;
          String label = interval;
          if (interval == "1W") label = "1 Week";
          if (interval == "6M") label = "6 Months";
          if (interval == "1Y") label = "1 Year";
          if (interval == "ALL") label = "ALL";

          return Expanded(
            child: InkWell(
              onTap: () => _viewModel.setActiveInterval(interval),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? (isValuation ? AppColors.positive : AppColors.dividend)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.black : theme.subtext,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Interactive 120Hz Snapping Line Chart with Touch Crosshairs & Bezier Curve
// -----------------------------------------------------------------------------
class InteractiveHistoryChart extends StatefulWidget {
  final List<ChartPoint> points;
  const InteractiveHistoryChart({super.key, required this.points});

  @override
  State<InteractiveHistoryChart> createState() => _InteractiveHistoryChartState();
}

class _InteractiveHistoryChartState extends State<InteractiveHistoryChart> {
  int _touchIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    if (widget.points.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.border),
        ),
        child: const Center(child: Text("No chart data points available", style: TextStyle(color: Colors.grey))),
      );
    }

    // Snapping data binding
    final ChartPoint activePoint = _touchIndex >= 0 && _touchIndex < widget.points.length
        ? widget.points[_touchIndex]
        : widget.points.last;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active Data Point HUD Display / Tooltip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.positive,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activePoint.date,
                    style: theme.subtitleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.text,
                    ),
                  ),
                ],
              ),
              Text(
                "\$${activePoint.value.toStringAsFixed(2)} CAD",
                style: theme.cardTitleStyle.copyWith(
                  color: AppColors.positive,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Standard Fixed-Height Smooth Bezier Line Canvas
          GestureDetector(
            onPanStart: (details) => _updateTouchIndex(details.localPosition.dx),
            onPanUpdate: (details) => _updateTouchIndex(details.localPosition.dx),
            onPanEnd: (_) => setState(() => _touchIndex = -1),
            onTapDown: (details) => _updateTouchIndex(details.localPosition.dx),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: _ChartPainter(
                  points: widget.points,
                  touchIndex: _touchIndex,
                  isDark: theme.isDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateTouchIndex(double touchX) {
    if (widget.points.length <= 1) {
      setState(() => _touchIndex = 0);
      return;
    }
    final double width = context.size?.width ?? 300.0;
    final double segmentWidth = width / (widget.points.length - 1);
    int index = (touchX / segmentWidth).round();
    index = index.clamp(0, widget.points.length - 1);
    setState(() => _touchIndex = index);
  }
}

class _ChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final int touchIndex;
  final bool isDark;

  _ChartPainter({
    required this.points,
    required this.touchIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final values = points.map((p) => p.value).toList();
    double maxVal = values.reduce(math.max);
    double minVal = values.reduce(math.min);
    if (maxVal == minVal) {
      maxVal += 1.0;
      minVal -= 1.0;
    }
    final double diff = maxVal - minVal;

    // 1. Crisp Dashed Background Grid Lines (Y-axis helpers)
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2838) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    for (int i = 0; i <= 3; i++) {
      final double y = size.height * (i / 3.0);
      double dashX = 0;
      const double dashWidth = 4.0;
      const double dashSpace = 4.0;
      while (dashX < size.width) {
        canvas.drawLine(
          Offset(dashX, y),
          Offset(math.min(dashX + dashWidth, size.width), y),
          gridPaint,
        );
        dashX += dashWidth + dashSpace;
      }
    }

    // Map point positions on canvas with crisp top & bottom inset padding
    final List<Offset> coordinates = [];
    final double stepX = points.length > 1 ? size.width / (points.length - 1) : size.width;

    for (int i = 0; i < points.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((points[i].value - minVal) / diff) * (size.height - 30) - 15;
      coordinates.add(Offset(x, y));
    }

    // Smooth Cubic Bezier Path calculation
    final linePath = Path();
    linePath.moveTo(coordinates[0].dx, coordinates[0].dy);

    for (int i = 0; i < coordinates.length - 1; i++) {
      final p0 = coordinates[i];
      final p1 = coordinates[i + 1];

      final control1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final control2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      linePath.cubicTo(
        control1.dx, control1.dy,
        control2.dx, control2.dy,
        p1.dx, p1.dy,
      );
    }

    // 2. Dual-Layer Ambient Neon Glow Line
    final ambientGlowPaint = Paint()
      ..color = AppColors.positive.withValues(alpha: 0.22)
      ..strokeWidth = 6.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final primaryLinePaint = Paint()
      ..color = AppColors.positive
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(linePath, ambientGlowPaint);
    canvas.drawPath(linePath, primaryLinePaint);

    // 3. Multi-Stop Fading Ambient Gradient Below Line
    final fillPath = Path.from(linePath);
    fillPath.lineTo(coordinates.last.dx, size.height);
    fillPath.lineTo(coordinates.first.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.positive.withValues(alpha: 0.32),
          AppColors.positive.withValues(alpha: 0.08),
          AppColors.positive.withValues(alpha: 0.00),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(fillPath, fillPaint);

    // 4. Sharp Dual-Ring Data Point Nodes
    final dotCenterPaint = Paint()
      ..color = AppColors.positive
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final dotBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (int i = 0; i < coordinates.length; i++) {
      canvas.drawCircle(coordinates[i], 4.5, dotCenterPaint);
      canvas.drawCircle(coordinates[i], 4.5, dotBorderPaint);
    }

    // 5. Active Touch Highlighting Crosshair & Snapping Node
    final int activeIdx = touchIndex >= 0 ? touchIndex : coordinates.length - 1;
    final Offset node = coordinates[activeIdx];

    // Dashed vertical crosshair indicator line
    final crossPaint = Paint()
      ..color = isDark ? Colors.white60 : Colors.black45
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    double dashY = 0;
    const double lineDashHeight = 4.0;
    const double lineDashSpace = 3.0;
    while (dashY < size.height) {
      canvas.drawLine(
        Offset(node.dx, dashY),
        Offset(node.dx, math.min(dashY + lineDashHeight, size.height)),
        crossPaint,
      );
      dashY += lineDashHeight + lineDashSpace;
    }

    // Active glowing pulse ring & triple-concentric target node
    final outerPulsePaint = Paint()
      ..color = AppColors.positive.withValues(alpha: 0.35)
      ..isAntiAlias = true;

    final activeNodePaint = Paint()
      ..color = AppColors.positive
      ..isAntiAlias = true;

    final innerCorePaint = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;

    canvas.drawCircle(node, 12.0, outerPulsePaint);
    canvas.drawCircle(node, 7.0, activeNodePaint);
    canvas.drawCircle(node, 3.5, innerCorePaint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.touchIndex != touchIndex ||
        oldDelegate.points != points ||
        oldDelegate.isDark != isDark;
  }
}

// -----------------------------------------------------------------------------
// Clickable Grid Donut Card Component
// -----------------------------------------------------------------------------
class GridDonutCard extends StatelessWidget {
  final List<DonutChartItem> items;
  final String title;
  final String subtitle;
  final String centerLabel;
  final VoidCallback onPress;

  const GridDonutCard({
    super.key,
    required this.items,
    required this.title,
    required this.subtitle,
    required this.centerLabel,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    // Take top 3 allocations to list inside the card legend
    final topItems = items.take(3).toList();

    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.border, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            // Center-labelled Circular Donut Svg Painter
            SizedBox(
              width: 125,
              height: 125,
              child: CustomPaint(
                painter: _DonutPainter(
                  items: items,
                  centerLabel: centerLabel,
                  isDark: theme.isDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: theme.cardTitleStyle.copyWith(fontSize: 12)),
            const SizedBox(height: 8),

            // Top Allocations Legend List
            Column(
              children: topItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(color: theme.text, fontSize: 9, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${(item.percentage * 100).toStringAsFixed(0)}%",
                        style: TextStyle(color: theme.subtext, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutChartItem> items;
  final String centerLabel;
  final bool isDark;

  _DonutPainter({required this.items, required this.centerLabel, required this.isDark});

  Color _getShadowColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();
  }

  Color _getLightColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height * 0.68; // Squash height for 3D elliptical perspective
    final double chartWidth = width - 8.0;
    final double chartHeight = height - 8.0;
    final double depth = 12.0; // Thickness of the 3D pie slices

    // Draw drop shadow at the bottom
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.38 : 0.16)
      ..imageFilter = ImageFilter.blur(sigmaX: 7.0, sigmaY: 4.5);
    canvas.drawOval(
      Rect.fromLTWH(4.0, 4.0 + depth, chartWidth, chartHeight),
      shadowPaint,
    );

    // 1. Draw the 3D extrusion walls (bottom-up stack layer extrusion)
    for (int layer = depth.toInt(); layer >= 0; layer--) {
      double currentStartAngle = -math.pi / 2;
      for (var item in items) {
        final double sweepAngle = 2 * math.pi * item.percentage;
        if (sweepAngle == 0) continue;

        // Explode offset: shift slice outwards in its radial direction for a modern gap separation
        final double midAngle = currentStartAngle + sweepAngle / 2;
        final double shift = 2.5; // 2.5px gap separation
        final double shiftX = math.cos(midAngle) * shift;
        final double shiftY = math.sin(midAngle) * shift;

        final rect = Rect.fromLTWH(
          4.0 + shiftX,
          4.0 + shiftY + layer.toDouble(),
          chartWidth,
          chartHeight,
        );

        final wallPaint = Paint()
          ..color = _getShadowColor(item.color)
          ..style = PaintingStyle.fill;

        canvas.drawArc(
          rect,
          currentStartAngle + 0.02,
          sweepAngle - 0.04,
          true,
          wallPaint,
        );

        currentStartAngle += sweepAngle;
      }
    }

    // 2. Draw the top active slices (with linear gradients)
    double startAngle = -math.pi / 2;
    for (var item in items) {
      final double sweepAngle = 2 * math.pi * item.percentage;
      if (sweepAngle == 0) continue;

      final double midAngle = startAngle + sweepAngle / 2;
      final double shift = 2.5;
      final double shiftX = math.cos(midAngle) * shift;
      final double shiftY = math.sin(midAngle) * shift;

      final rect = Rect.fromLTWH(
        4.0 + shiftX,
        4.0 + shiftY,
        chartWidth,
        chartHeight,
      );

      final topPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getLightColor(item.color),
            item.color,
          ],
        ).createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        rect,
        startAngle + 0.02,
        sweepAngle - 0.04,
        true,
        topPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.isDark != isDark || oldDelegate.centerLabel != centerLabel;
  }
}
