import 'dart:math' as math;
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
  String _activeTab = "PERFORMANCE"; // "PERFORMANCE" | "ANALYTICS"

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
  late ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _viewModel = ProfileViewModel(apiService: apiService, profileId: widget.profileId);
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
      body: SafeArea(
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

                  // Horizontal Tabs (Performance / Analytics)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: theme.border, width: 1.5)),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton("Performance", "PERFORMANCE", theme),
                        _buildTabButton("Analytics", "ANALYTICS", theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Swapping views
                  Expanded(
                    child: _viewModel.activeTab == "PERFORMANCE"
                        ? _buildPerformanceTab(theme)
                        : _buildAnalyticsTab(theme),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tabKey, ThemeProvider theme) {
    final isActive = _viewModel.activeTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () => _viewModel.setActiveTab(tabKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.positive : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? theme.text : theme.subtext,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Performance Tab content: Chart + selector toggles + Stocks list
  Widget _buildPerformanceTab(ThemeProvider theme) {
    final stocks = _viewModel.profile?.stocks ?? [];

    return ListView(
      children: [
        // Touch Interactive History Line Chart
        InteractiveHistoryChart(points: _viewModel.chartPoints),
        const SizedBox(height: 16),

        // Valuation vs Dividend Toggle
        _buildModeToggle(theme),
        const SizedBox(height: 16),

        // Interval scrollselector
        _buildIntervalSelector(theme),
        const SizedBox(height: 24),

        // Holdings listings header
        Text(
          "Active Allocations",
          style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1),
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
                    const SizedBox(width: 12),
                    // Ticker text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stock.ticker, style: theme.cardTitleStyle.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(stock.name, style: theme.subtitleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Middle shares details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock.shares.toString(), style: theme.cardTitleStyle.copyWith(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text("shares", style: theme.subtitleStyle),
                      ],
                    ),
                    const SizedBox(width: 20),
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

  // Analytics Tab content: Toggles + Clickable Grid Cards
  Widget _buildAnalyticsTab(ThemeProvider theme) {
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

    final isValuation = _viewModel.chartMode == "VALUATION";

    return ListView(
      children: [
        // Mode toggle Valuation Breakdown vs Dividend Contribution
        _buildModeToggle(theme, subtitleText: true),
        const SizedBox(height: 24),

        if (isValuation) ...[
          // Grid containing Stock allocations & Sector allocations
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stockItems.isNotEmpty)
                Expanded(
                  child: GridDonutCard(
                    items: stockItems,
                    title: "Stock Weight",
                    subtitle: "${stockItems.length} Assets",
                    centerLabel: "Stocks",
                    onPress: () => context.push(
                      "/analysis?id=${widget.profileId}&type=stock",
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              const SizedBox(width: 16),
              if (sectorItems.isNotEmpty)
                Expanded(
                  child: GridDonutCard(
                    items: sectorItems,
                    title: "Sector Weight",
                    subtitle: "${sectorItems.length} Sectors",
                    centerLabel: "Sectors",
                    onPress: () => context.push(
                      "/analysis?id=${widget.profileId}&type=sector",
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ] else ...[
          // Centered Dividend Yield donut card
          if (divItems.isNotEmpty)
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.50,
                child: GridDonutCard(
                  items: divItems,
                  title: "Dividend Yield",
                  subtitle: "${divItems.length} Contributors",
                  centerLabel: "Dividends",
                  onPress: () => context.push(
                    "/analysis?id=${widget.profileId}&type=dividend",
                  ),
                ),
              ),
            )
          else
            const Center(child: Text("No dividend allocations found", style: TextStyle(color: Colors.grey))),
        ],
        const SizedBox(height: 40),
      ],
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
    final intervals = _viewModel.chartMode == "VALUATION"
        ? ["NOW", "1D", "5D", "1W", "1M", "3M", "6M", "1Y", "5Y", "ALL"]
        : ["NOW", "1Y", "3Y", "5Y", "ALL"];

    final isValuation = _viewModel.chartMode == "VALUATION";

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: intervals.length,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        itemBuilder: (context, index) {
          final interval = intervals[index];
          final isActive = _viewModel.activeInterval == interval;

          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: InkWell(
              onTap: () => _viewModel.setActiveInterval(interval),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isValuation ? AppColors.positive : AppColors.dividend)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    interval,
                    style: TextStyle(
                      color: isActive ? Colors.white : theme.subtext,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Interactive 120Hz Snapping Line Chart with Touch Crosshairs
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
        height: 200,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        children: [
          // Snap values HUD display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activePoint.date,
                style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                "\$${activePoint.value.toStringAsFixed(2)}",
                style: theme.cardTitleStyle.copyWith(
                  color: AppColors.positive,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gesture listener overlaying the canvas
          GestureDetector(
            onPanStart: (details) => _updateTouchIndex(details.localPosition.dx),
            onPanUpdate: (details) => _updateTouchIndex(details.localPosition.dx),
            onPanEnd: (_) => setState(() => _touchIndex = -1),
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
    final double maxVal = values.reduce(math.max);
    final double minVal = values.reduce(math.min);
    final double diff = maxVal - minVal;

    // Draw horizontal grid lines (Y-axis helpers)
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF222429) : const Color(0xFFE5E7EB)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 4; i++) {
      final double y = size.height * (i / 3.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Map point positions on the canvas
    final List<Offset> coordinates = [];
    final double stepX = points.length > 1 ? size.width / (points.length - 1) : size.width;

    for (int i = 0; i < points.length; i++) {
      final double x = i * stepX;
      // Guard against divide by zero (e.g. single NOW point or flat history)
      final double y = diff > 0
          ? size.height - ((points[i].value - minVal) / diff) * size.height
          : size.height / 2;
      coordinates.add(Offset(x, y));
    }

    // Draw the historical trend line
    final linePaint = Paint()
      ..color = AppColors.positive
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(coordinates[0].dx, coordinates[0].dy);
    for (int i = 1; i < coordinates.length; i++) {
      linePath.lineTo(coordinates[i].dx, coordinates[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw fading gradient below trend line
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.positive.withValues(alpha: 0.20),
          AppColors.positive.withValues(alpha: 0.00),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final gradPath = Path()
      ..moveTo(coordinates[0].dx, coordinates[0].dy);
    for (int i = 1; i < coordinates.length; i++) {
      gradPath.lineTo(coordinates[i].dx, coordinates[i].dy);
    }
    gradPath.lineTo(coordinates.last.dx, size.height);
    gradPath.lineTo(coordinates.first.dx, size.height);
    gradPath.close();
    canvas.drawPath(gradPath, gradientPaint);

    // Render Snapping Crosshair and Node badge if active
    final int activeIdx = touchIndex >= 0 ? touchIndex : points.length - 1;
    final Offset node = coordinates[activeIdx];

    // Vertical indicator line
    final crossPaint = Paint()
      ..color = isDark ? Colors.white30 : Colors.black26
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(node.dx, 0), Offset(node.dx, size.height), crossPaint);

    // Snapping node circle
    final outerNodePaint = Paint()..color = AppColors.positive.withValues(alpha: 0.2);
    final innerNodePaint = Paint()..color = AppColors.positive;

    canvas.drawCircle(node, 8.0, outerNodePaint);
    canvas.drawCircle(node, 4.0, innerNodePaint);
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
              width: 90,
              height: 90,
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

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double innerRadius = radius - 8.5; // Stroke width 8

    // Draw background placeholder circle
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF222429) : const Color(0xFFF3F4F6)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, innerRadius, bgPaint);

    double startAngle = -math.pi / 2; // Start from top 12 o'clock

    for (var item in items) {
      final double sweepAngle = 2 * math.pi * item.percentage;
      final arcPaint = Paint()
        ..color = item.color
        ..strokeWidth = 7.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw active circular arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle - 0.05, // minor gap spacing
        false,
        arcPaint,
      );

      startAngle += sweepAngle;
    }

    // Render center label inside the donut hole
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.isDark != isDark;
  }
}
