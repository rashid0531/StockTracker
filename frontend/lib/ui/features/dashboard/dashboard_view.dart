import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/profile.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';
import '../profile/widgets/modern_history_chart.dart';
import '../../core/widgets/hover_button.dart';

const List<String> _monthNames = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

const List<String> _weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

const List<String> _weekDaysFull = [
  "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
];

class DashboardViewModel extends ChangeNotifier {
  final ApiService apiService;
  List<InvestmentProfile> _profiles = [];
  bool _isLoading = true;

  // Persistent cost targets
  double _coffeeCost = 100.0;
  double _utilityCost = 300.0;
  double _housingCost = 2000.0;
  double _fireCost = 4000.0;

  // Calendar State
  List<DividendCalendarEvent> _calendarEvents = [];
  bool _isLoadingCalendar = false;

  // History State
  List<TransactionRecord> _transactions = [];
  bool _isLoadingTransactions = false;
  String _historyProfileFilter = "ALL";
  String _historyTypeFilter = "ALL";
  String _historySearchQuery = "";

  // Dividend Tab State
  String _dividendProfileId = "ALL";
  String _activeDividendInterval = "1W";
  List<ChartPoint> _dividendChartPoints = [];
  bool _isLoadingDividend = false;

  // Actual Income State
  List<DividendReceived> _receivedDividends = [];
  double _totalReceivedAllTime = 0.0;
  double _currentYearReceived = 0.0;
  bool _isLoadingReceived = false;

  DashboardViewModel({required this.apiService});

  List<InvestmentProfile> get profiles => _profiles;
  bool get isLoading => _isLoading;

  double get coffeeCost => _coffeeCost;
  double get utilityCost => _utilityCost;
  double get housingCost => _housingCost;
  double get fireCost => _fireCost;

  List<DividendCalendarEvent> get calendarEvents => _calendarEvents;
  bool get isLoadingCalendar => _isLoadingCalendar;

  List<TransactionRecord> get transactions => _transactions;
  bool get isLoadingTransactions => _isLoadingTransactions;
  String get historyProfileFilter => _historyProfileFilter;
  String get historyTypeFilter => _historyTypeFilter;
  String get historySearchQuery => _historySearchQuery;

  String get dividendProfileId => _dividendProfileId;
  String get activeDividendInterval => _activeDividendInterval;
  List<ChartPoint> get dividendChartPoints => _dividendChartPoints;
  bool get isLoadingDividend => _isLoadingDividend;

  List<DividendReceived> get receivedDividends => _receivedDividends;
  double get totalReceivedAllTime => _totalReceivedAllTime;
  double get currentYearReceived => _currentYearReceived;
  bool get isLoadingReceived => _isLoadingReceived;

  InvestmentProfile? get selectedDividendProfile {
    if (_dividendProfileId == "ALL" || _profiles.isEmpty) return null;
    return _profiles.firstWhere((p) => p.id == _dividendProfileId, orElse: () => _profiles[0]);
  }

  double get currentSelectedDividendAmount {
    if (_dividendProfileId == "ALL") {
      return totalDividendCAD;
    }
    final p = selectedDividendProfile;
    if (p == null) return 0;
    return apiService.convertCurrencyToCAD(p.annualDividend, p.type == "TFSA" ? "CAD" : "USD");
  }

  void setDividendProfileId(String id) {
    _dividendProfileId = id;
    loadDividendTab();
  }

  void setActiveDividendInterval(String interval) {
    _activeDividendInterval = interval;
    loadDividendTab();
  }

  Future<void> loadDividendTab() async {
    _isLoadingDividend = true;
    notifyListeners();

    try {
      // Use the first profile id as fallback (no more hardcoded UUID)
      final fallbackId = _profiles.isNotEmpty ? _profiles[0].id : ApiService.mockUserId;
      final pid = _dividendProfileId == "ALL" ? fallbackId : _dividendProfileId;
      _dividendChartPoints = await apiService.getChartPoints(
        pid,
        _activeDividendInterval,
        true,
      );
    } catch (e) {
      debugPrint("Error loading dividend tab: $e");
    } finally {
      _isLoadingDividend = false;
      notifyListeners();
    }
  }

  Future<void> loadReceivedDividends() async {
    _isLoadingReceived = true;
    notifyListeners();
    try {
      final data = await apiService.getReceivedDividends();
      _totalReceivedAllTime = (data['total_received_all_time'] as num?)?.toDouble() ?? 0.0;
      _currentYearReceived = (data['current_year_received'] as num?)?.toDouble() ?? 0.0;
      final records = data['records'] as List? ?? [];
      _receivedDividends = records.map((r) => DividendReceived.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Error loading received dividends: $e");
    } finally {
      _isLoadingReceived = false;
      notifyListeners();
    }
  }

  Future<bool> logDividendReceived({
    required String ticker,
    required String paymentDate,
    required double amountPerShare,
    required double sharesAtPayment,
    required double totalReceived,
    required String currency,
    String? notes,
  }) async {
    final ok = await apiService.logDividendReceived(
      ticker: ticker,
      paymentDate: paymentDate,
      amountPerShare: amountPerShare,
      sharesAtPayment: sharesAtPayment,
      totalReceived: totalReceived,
      currency: currency,
      notes: notes,
    );
    if (ok) await loadReceivedDividends();
    return ok;
  }

  double get totalValuationCAD {
    double total = 0;
    for (var p in _profiles) {
      final currency = p.type == "TFSA" ? "CAD" : "USD";
      total += apiService.convertCurrencyToCAD(p.totalValue, currency);
    }
    return total;
  }

  double get totalDividendCAD {
    double total = 0;
    for (var p in _profiles) {
      final currency = p.type == "TFSA" ? "CAD" : "USD";
      total += apiService.convertCurrencyToCAD(p.annualDividend, currency);
    }
    return total;
  }

  double get aggregateChangePercent {
    if (_profiles.isEmpty) return 0;
    double weightedChange = 0;
    double totalVal = totalValuationCAD;
    if (totalVal == 0) return 0;

    for (var p in _profiles) {
      final currency = p.type == "TFSA" ? "CAD" : "USD";
      final valCAD = apiService.convertCurrencyToCAD(p.totalValue, currency);
      final weight = valCAD / totalVal;
      weightedChange += p.totalChangePercent * weight;
    }
    return weightedChange;
  }

  Map<String, double> get currencyBreakdowns {
    final Map<String, double> totals = {};
    for (var p in _profiles) {
      for (var s in p.stocks) {
        totals[s.currency] = (totals[s.currency] ?? 0.0) + s.value;
      }
    }
    return totals;
  }

  List<TransactionRecord> get filteredTransactions {
    var list = List<TransactionRecord>.from(_transactions);
    if (_historyProfileFilter != "ALL") {
      list = list.where((t) => t.profileId == _historyProfileFilter).toList();
    }
    if (_historyTypeFilter != "ALL") {
      list = list.where((t) => t.type.toUpperCase() == _historyTypeFilter.toUpperCase()).toList();
    }
    if (_historySearchQuery.trim().isNotEmpty) {
      final q = _historySearchQuery.trim().toLowerCase();
      list = list.where((t) => t.ticker.toLowerCase().contains(q) || t.stockName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void setHistoryProfileFilter(String id) {
    _historyProfileFilter = id;
    notifyListeners();
  }

  void setHistoryTypeFilter(String type) {
    _historyTypeFilter = type;
    notifyListeners();
  }

  void setHistorySearchQuery(String q) {
    _historySearchQuery = q;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _isLoadingTransactions = true;
    notifyListeners();

    try {
      _transactions = await apiService.getTransactions();
    } catch (e) {
      debugPrint("Error loading transactions: $e");
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profiles = await apiService.getProfiles();
      await loadFireMilestones();
      await loadTransactions();
    } catch (e) {
      debugPrint("Error loading dashboard: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFireMilestones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _coffeeCost = prefs.getDouble('coffee_cost') ?? 100.0;
      _utilityCost = prefs.getDouble('utility_cost') ?? 300.0;
      _housingCost = prefs.getDouble('housing_cost') ?? 2000.0;
      _fireCost = prefs.getDouble('fire_cost') ?? 4000.0;
    } catch (e) {
      debugPrint("Error loading FIRE milestones: $e");
    }
  }

  Future<void> updateCoffeeCost(double val) async {
    _coffeeCost = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('coffee_cost', val);
    } catch (e) {
      debugPrint("Error saving coffee cost: $e");
    }
  }

  Future<void> updateUtilityCost(double val) async {
    _utilityCost = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('utility_cost', val);
    } catch (e) {
      debugPrint("Error saving utility cost: $e");
    }
  }

  Future<void> updateHousingCost(double val) async {
    _housingCost = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('housing_cost', val);
    } catch (e) {
      debugPrint("Error saving housing cost: $e");
    }
  }

  Future<void> updateFireCost(double val) async {
    _fireCost = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fire_cost', val);
    } catch (e) {
      debugPrint("Error saving FIRE cost: $e");
    }
  }

  Future<void> loadCalendar() async {
    _isLoadingCalendar = true;
    notifyListeners();

    try {
      _calendarEvents = await apiService.getDividendCalendar(ApiService.mockUserId);
    } catch (e) {
      debugPrint("Error loading calendar: $e");
    } finally {
      _isLoadingCalendar = false;
      notifyListeners();
    }
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final DashboardViewModel _viewModel = DashboardViewModel(apiService: ApiService());
  int _currentTabIndex = 0;

  // Calendar UI Helper State
  DateTime _focusedMonth = DateTime(2026, 7, 1);
  DateTime? _selectedDate = DateTime(2026, 7, 28);
  bool _isCalendarGridView = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _viewModel.loadDashboard();
      await _viewModel.loadCalendar();
      await _viewModel.loadReceivedDividends();
    });
  }

  void _showSaveFeedback(ThemeProvider theme) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text("💾", style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(
              "Cost target saved and updated!",
              style: TextStyle(color: theme.text, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: theme.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.border, width: 1.5),
        ),
      ),
    );
  }

  String formatCAD(double val) {
    return "\$${val.toStringAsFixed(2)}";
  }

  Widget _buildMultiCurrencyRow(ThemeProvider theme) {
    final breakdowns = _viewModel.currencyBreakdowns;
    if (breakdowns.isEmpty) return const SizedBox.shrink();

    final List<String> parts = [];
    final sortedCurrencies = breakdowns.keys.toList()..sort();
    for (var currency in sortedCurrencies) {
      final value = breakdowns[currency] ?? 0.0;
      if (value > 0) {
        String symbol = "\$";
        if (currency == "USD") {
          symbol = "US\$";
        } else if (currency == "AUD") {
          symbol = "A\$";
        } else if (currency == "GBP") {
          symbol = "£";
        }
        
        parts.add("$symbol${value.toStringAsFixed(2)}");
      }
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      "Holdings: ${parts.join('  •  ')}",
      style: theme.subtitleStyle.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: theme.subtext.withValues(alpha: 0.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.bg,
      drawer: Drawer(
        backgroundColor: theme.bg,
        child: _buildWebSidePanel(theme),
      ),
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

              return _buildTabContent(theme);
            },
          ),
        ),
      ),

    );
  }

  Widget _buildWebSidePanel(ThemeProvider theme) {
    final navItems = [
      {"icon": "📊", "label": "Portfolio", "index": 0},
      {"icon": "💰", "label": "Dividend", "index": 1},
      {"icon": "📜", "label": "History", "index": 4},
      {"icon": "⚙️", "label": "Settings", "index": 5},
    ];

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: theme.card,
        border: Border(
          right: BorderSide(color: theme.border, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // App Logo & Branding Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.positive.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/solorash_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text("⚡", style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "StockTracker",
                        style: theme.titleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        "Wealth Dashboard",
                        style: theme.subtitleStyle.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Side Navigation Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: navItems.map((item) {
                final int idx = item["index"] as int;
                final bool isActive = _currentTabIndex == idx;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentTabIndex = idx;
                      });
                      if (idx == 1) {
                        _viewModel.loadDividendTab();
                      } else if (idx == 3) {
                        _viewModel.loadCalendar();
                      } else if (idx == 4) {
                        _viewModel.loadTransactions();
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.positive.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive ? AppColors.positive.withValues(alpha: 0.4) : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            item["icon"] as String,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item["label"] as String,
                            style: TextStyle(
                              color: isActive ? AppColors.positive : theme.text,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (isActive) ...[
                            const Spacer(),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.positive,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom Quick Action / User Card
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.isDark ? const Color(0xFF14171C) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                children: [
                  const Text("👤", style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Solo Rash", style: theme.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text("PRO Member", style: TextStyle(color: AppColors.positive, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeProvider theme) {
    switch (_currentTabIndex) {
      case 1:
        return _buildDividendTab(theme);
      case 2:
        return _buildFireTab(theme);
      case 3:
        return _buildCalendarTab(theme);
      case 4:
        return _buildHistoryTab(theme);
      case 5:
        return _buildSettingsTab(theme);
      case 0:
      default:
        return _buildPortfolioTab(theme);
    }
  }

  // 1. Portfolio Tab (Original Dashboard View)
  Widget _buildPortfolioTab(ThemeProvider theme) {
    final hasPositiveChange = _viewModel.aggregateChangePercent >= 0;

    return RefreshIndicator(
      onRefresh: () async {
        await _viewModel.loadDashboard();
        await _viewModel.loadCalendar();
      },
      color: AppColors.positive,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // Top Header Row with SoloRash Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: theme.text),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.positive.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: Image.asset(
                        'assets/images/solorash_logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Text("⚡", style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("My Net Worth", style: theme.titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w900)),
                      Text("WealthTracker by Solo Rash", style: theme.subtitleStyle.copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go("/hub"),
                    tooltip: "Back to Hub",
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.border),
                      ),
                      child: Text("🏡", style: TextStyle(color: theme.text, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => context.push("/import"),
                    tooltip: "Import CSV",
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.border),
                      ),
                      child: Text("📥", style: TextStyle(color: theme.text, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Valuation Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: theme.border, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Portfolio Value (CAD)",
                  style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatCAD(_viewModel.totalValuationCAD),
                      style: theme.titleStyle.copyWith(fontSize: 32, letterSpacing: -0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (hasPositiveChange ? AppColors.positive : AppColors.negative).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (hasPositiveChange ? AppColors.positive : AppColors.negative).withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        "${hasPositiveChange ? "+" : ""}${_viewModel.aggregateChangePercent.toStringAsFixed(2)}%",
                        style: TextStyle(
                          color: hasPositiveChange ? AppColors.positive : AppColors.negative,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMultiCurrencyRow(theme),
                const SizedBox(height: 12),
                Divider(color: theme.border),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Annual Passive Dividend",
                          style: theme.subtitleStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCAD(_viewModel.totalDividendCAD),
                          style: theme.cardTitleStyle.copyWith(color: AppColors.dividend),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        if (_viewModel.profiles.isNotEmpty) {
                          context.push("/profile/${_viewModel.profiles[0].id}");
                        }
                      },
                      child: const Row(
                        children: [
                          Text(
                            "Insights",
                            style: TextStyle(
                              color: AppColors.positive,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text("➔", style: TextStyle(color: AppColors.positive, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Investment Profiles Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Investment & Asset Profiles",
                style: theme.subtitleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              InkWell(
                onTap: () => context.push("/create-asset"),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.positive),
                      SizedBox(width: 4),
                      Text("Create Profile", style: TextStyle(color: AppColors.positive, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._viewModel.profiles.map((profile) {
            final profileCurrency = profile.type == "TFSA" ? "CAD" : "USD";
            final changeIsPositive = profile.totalChangePercent >= 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: InkWell(
                onTap: () => context.push("/profile/${profile.id}"),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.isDark ? const Color(0xFF1E2126) : const Color(0xFFE5E7EB),
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.border),
                              ),
                              child: Center(
                                child: Text(
                                  profile.name.substring(0, 2).toUpperCase(),
                                  style: TextStyle(
                                    color: theme.text,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.name,
                                    style: theme.cardTitleStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.type == "TFSA" 
                                        ? "Questrade • Wealthsimple"
                                        : "Wealthsimple • RBC",
                                    style: theme.subtitleStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            profileCurrency == "CAD"
                                ? "\$${profile.totalValue.toStringAsFixed(2)}"
                                : "US\$${profile.totalValue.toStringAsFixed(2)}",
                            style: theme.cardTitleStyle.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (changeIsPositive ? AppColors.positive : AppColors.negative).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (changeIsPositive ? AppColors.positive : AppColors.negative).withValues(alpha: 0.24),
                              ),
                            ),
                            child: Text(
                              "${changeIsPositive ? "+" : ""}${profile.totalChangePercent.toStringAsFixed(2)}%",
                              style: TextStyle(
                                color: changeIsPositive ? AppColors.positive : AppColors.negative,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 2. FIRE Milestones Tab
  Widget _buildFireTab(ThemeProvider theme) {
    final double monthlyDividend = _viewModel.totalDividendCAD / 12.0;

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: theme.text),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 8),
            Text("FIRE Milestones", style: theme.titleStyle),
          ]
        ),
        Text("Track how much of your expenses are covered by passive dividend income.", style: theme.subtitleStyle),
        const SizedBox(height: 24),

        // Monthly Dividend Display Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Monthly Passive Income",
                style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                formatCAD(monthlyDividend),
                style: theme.titleStyle.copyWith(fontSize: 28, color: AppColors.dividend),
              ),
              const SizedBox(height: 4),
              Text(
                "Based on total projected annual dividends of ${formatCAD(_viewModel.totalDividendCAD)}",
                style: theme.subtitleStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        Text("Milestone Targets", style: theme.cardTitleStyle.copyWith(fontSize: 15)),
        const SizedBox(height: 12),

        _buildMilestoneProgressCard("☕ Level 1: Coffee & Snacks", monthlyDividend, _viewModel.coffeeCost, theme, (newVal) async {
          await _viewModel.updateCoffeeCost(newVal);
          _showSaveFeedback(theme);
        }),
        _buildMilestoneProgressCard("🔌 Level 2: Utilities & Phone", monthlyDividend, _viewModel.utilityCost, theme, (newVal) async {
          await _viewModel.updateUtilityCost(newVal);
          _showSaveFeedback(theme);
        }),
        _buildMilestoneProgressCard("🏠 Level 3: Housing & Rent", monthlyDividend, _viewModel.housingCost, theme, (newVal) async {
          await _viewModel.updateHousingCost(newVal);
          _showSaveFeedback(theme);
        }),
        _buildMilestoneProgressCard("🚀 Level 4: Lean FIRE Goals", monthlyDividend, _viewModel.fireCost, theme, (newVal) async {
          await _viewModel.updateFireCost(newVal);
          _showSaveFeedback(theme);
        }),
      ],
    );
  }

  Widget _buildMilestoneProgressCard(
    String title,
    double monthlyDividend,
    double targetCost,
    ThemeProvider theme,
    ValueChanged<double> onUpdateCost,
  ) {
    final double percent = targetCost > 0 ? (monthlyDividend / targetCost) * 100 : 0;
    final double cappedPercent = percent.clamp(0, 100);
    final isCovered = percent >= 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.cardTitleStyle.copyWith(fontSize: 14)),
              IconButton(
                icon: const Text("✏️", style: TextStyle(fontSize: 12)),
                onPressed: () => _showCostEditDialog(title, targetCost, onUpdateCost),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Target: ${formatCAD(targetCost)} / mo",
                style: theme.subtitleStyle,
              ),
              if (isCovered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.positive.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.positive.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    "Covered! 🎉",
                    style: TextStyle(color: AppColors.positive, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Text(
                  "${percent.toStringAsFixed(1)}%",
                  style: TextStyle(color: AppColors.dividend, fontSize: 11, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: cappedPercent / 100,
              minHeight: 8,
              backgroundColor: theme.isDark ? const Color(0xFF1E2126) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCovered ? AppColors.positive : AppColors.dividend,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCostEditDialog(String title, double currentCost, ValueChanged<double> onUpdateCost) {
    final controller = TextEditingController(text: currentCost.toStringAsFixed(0));
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.card,
          title: Text("Edit Cost Target", style: theme.cardTitleStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Set the monthly cost for:", style: theme.subtitleStyle),
              Text(title, style: theme.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: "\$ ",
                  hintText: "Enter amount",
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.positive),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.border),
                  ),
                ),
                style: TextStyle(color: theme.text),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: theme.subtext)),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null && val >= 0) {
                  onUpdateCost(val);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.positive),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 3. Dividend Calendar Tab
  Widget _buildCalendarTab(ThemeProvider theme) {
    if (_viewModel.isLoadingCalendar) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.positive),
      );
    }

    final hasUpcomingExDiv = _viewModel.calendarEvents.any((e) => e.ticker == "AAPL");

    return RefreshIndicator(
      onRefresh: _viewModel.loadCalendar,
      color: AppColors.positive,
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu, color: theme.text),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dividend Calendar", style: theme.titleStyle),
                        Text("Chronological schedule of ex-dividend dates and payments.", style: theme.subtitleStyle),
                      ],
                    ),
                  ],
                ),
              ),
              // View Mode Toggle (Grid vs List)
              Container(
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.border, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isCalendarGridView = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isCalendarGridView ? AppColors.positive.withValues(alpha: 0.18) : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: _isCalendarGridView ? AppColors.positive : theme.subtext,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isCalendarGridView = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_isCalendarGridView ? AppColors.positive.withValues(alpha: 0.18) : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.format_list_bulleted_rounded,
                          size: 18,
                          color: !_isCalendarGridView ? AppColors.positive : theme.subtext,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 7-day Alert Warning Banner
          if (hasUpcomingExDiv)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.28), width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🔔", style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Upcoming Ex-Dividend Alert",
                          style: TextStyle(
                            color: Color(0xFFFFC107),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "AAPL goes ex-dividend on July 28, 2026. Maintain your position to capture the projected dividend payment of \$2.52 USD on August 14.",
                          style: theme.subtitleStyle.copyWith(
                            color: theme.isDark ? Colors.white70 : Colors.black87,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (_isCalendarGridView)
            _buildInteractiveCalendarGrid(theme)
          else
            _buildAgendaListView(theme),
        ],
      ),
    );
  }

  // Interactive Monthly Calendar Grid Component
  Widget _buildInteractiveCalendarGrid(ThemeProvider theme) {
    final monthName = _monthNames[_focusedMonth.month - 1];
    final year = _focusedMonth.year;

    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startWeekday = firstDay.weekday % 7; // 0 for Sun, 1 for Mon...
    final totalGridCells = startWeekday + daysInMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Navigation Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.border, width: 1.5),
          ),
          child: Column(
            children: [
              // Navigation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: theme.text),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                        _selectedDate = null;
                      });
                    },
                  ),
                  Row(
                    children: [
                      Text(
                        "$monthName $year",
                        style: theme.cardTitleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _focusedMonth = DateTime(2026, 7, 1);
                            _selectedDate = DateTime(2026, 7, 28);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.positive.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Today",
                            style: TextStyle(color: AppColors.positive, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: theme.text),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                        _selectedDate = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Weekdays Labels Header
              Row(
                children: _weekdays.map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: theme.subtext,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // 7-Column Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalGridCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  if (index < startWeekday) {
                    return const SizedBox(); // Empty offset cell
                  }

                  final dayNum = index - startWeekday + 1;
                  final currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                  final dateStr = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

                  // Match events on this day
                  final exEvents = _viewModel.calendarEvents.where((e) => e.exDividendDate == dateStr).toList();
                  final payEvents = _viewModel.calendarEvents.where((e) => e.paymentDate == dateStr).toList();
                  final totalEvents = exEvents.length + payEvents.length;
                  final hasEvents = totalEvents > 0;

                  final isSelected = _selectedDate != null &&
                      _selectedDate!.year == currentDate.year &&
                      _selectedDate!.month == currentDate.month &&
                      _selectedDate!.day == currentDate.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = currentDate;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.positive.withValues(alpha: 0.22)
                            : hasEvents
                                ? (theme.isDark ? const Color(0xFF1E222A) : const Color(0xFFEFEFF4))
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.positive
                              : hasEvents
                                  ? (exEvents.isNotEmpty ? const Color(0xFFFFB300) : AppColors.positive)
                                  : Colors.transparent,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$dayNum",
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.positive
                                  : hasEvents
                                      ? theme.text
                                      : theme.subtext.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: isSelected || hasEvents ? FontWeight.w900 : FontWeight.normal,
                            ),
                          ),
                          if (hasEvents) ...[
                            const SizedBox(height: 3),
                            if (totalEvents > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.positive
                                      : (exEvents.isNotEmpty && payEvents.isNotEmpty
                                          ? const Color(0xFFFFB300)
                                          : (exEvents.isNotEmpty ? const Color(0xFFFFB300) : AppColors.positive)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "$totalEvents",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (exEvents.isNotEmpty)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFB300),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (payEvents.isNotEmpty)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: const BoxDecoration(
                                        color: AppColors.positive,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Calendar Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFFB300), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("Ex-Dividend Date", style: theme.subtitleStyle.copyWith(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.positive, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text("Payment Date", style: theme.subtitleStyle.copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Selected Date Event Details
        _buildSelectedDateEventsSection(theme),
      ],
    );
  }

  // Selected Date Events Details Section
  Widget _buildSelectedDateEventsSection(ThemeProvider theme) {
    if (_selectedDate == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Month Overview", style: theme.cardTitleStyle.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          _buildMonthEventsOverview(theme),
        ],
      );
    }

    final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    final dayOfWeekName = _weekDaysFull[_selectedDate!.weekday % 7];
    final monthName = _monthNames[_selectedDate!.month - 1];
    final dayName = "$dayOfWeekName, $monthName ${_selectedDate!.day}, ${_selectedDate!.year}";

    final dateExEvents = _viewModel.calendarEvents.where((e) => e.exDividendDate == dateStr).toList();
    final datePayEvents = _viewModel.calendarEvents.where((e) => e.paymentDate == dateStr).toList();
    final totalDayEvents = dateExEvents.length + datePayEvents.length;

    double dayTotalPayout = 0;
    for (var e in dateExEvents) {
      dayTotalPayout += e.projectedPayout;
    }
    for (var e in datePayEvents) {
      dayTotalPayout += e.projectedPayout;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Events for Selected Day", style: theme.cardTitleStyle.copyWith(fontSize: 15)),
                Text(dayName, style: theme.subtitleStyle.copyWith(color: AppColors.positive, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _selectedDate = null),
              child: const Text("Show Month Overview", style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (totalDayEvents > 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.positive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.positive.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$totalDayEvents Same-Day Events",
                      style: const TextStyle(
                        color: AppColors.positive,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${dateExEvents.length} Ex-Dividend • ${datePayEvents.length} Payouts",
                      style: theme.subtitleStyle.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Total Day Payout",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "\$${dayTotalPayout.toStringAsFixed(2)}",
                      style: theme.cardTitleStyle.copyWith(color: AppColors.positive, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),

        if (totalDayEvents == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border),
            ),
            child: Center(
              child: Text(
                "No dividend events scheduled for $dayName",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else ...[
          ...dateExEvents.map((e) => _buildCalendarEventCard(theme, e, isExDiv: true)),
          ...datePayEvents.map((e) => _buildCalendarEventCard(theme, e, isExDiv: false)),
        ],
      ],
    );
  }

  // Month Overview Event Cards List
  Widget _buildMonthEventsOverview(ThemeProvider theme) {
    final monthEvents = _viewModel.calendarEvents.where((e) {
      final exMatch = e.exDividendDate != null &&
          e.exDividendDate!.startsWith("${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}");
      final payMatch = e.paymentDate != null &&
          e.paymentDate!.startsWith("${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}");
      return exMatch || payMatch;
    }).toList();

    if (monthEvents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border),
        ),
        child: Center(
          child: Text(
            "No dividend events scheduled for ${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: monthEvents.map((e) {
        final isExDivThisMonth = e.exDividendDate != null &&
            e.exDividendDate!.startsWith("${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}");
        return _buildCalendarEventCard(theme, e, isExDiv: isExDivThisMonth);
      }).toList(),
    );
  }

  // Individual Event Card Component
  Widget _buildCalendarEventCard(ThemeProvider theme, DividendCalendarEvent event, {required bool isExDiv}) {
    final isAapl = event.ticker == "AAPL";
    final eventDate = isExDiv ? event.exDividendDate : event.paymentDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExDiv ? const Color(0xFFFFB300).withValues(alpha: 0.5) : theme.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Ticker badge
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isExDiv
                  ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                  : (theme.isDark ? const Color(0xFF1E2126) : const Color(0xFFF3F4F6)),
              shape: BoxShape.circle,
              border: Border.all(color: isExDiv ? const Color(0xFFFFB300) : theme.border),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    event.ticker,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: isExDiv ? const Color(0xFFFFB300) : theme.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Event Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(event.ticker, style: theme.cardTitleStyle.copyWith(fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isExDiv
                            ? const Color(0xFFFFB300).withValues(alpha: 0.18)
                            : AppColors.positive.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isExDiv ? "Ex-Dividend" : "Payment Date",
                        style: TextStyle(
                          color: isExDiv ? const Color(0xFFFFC107) : AppColors.positive,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isExDiv ? "Ex-Date: ${eventDate ?? 'N/A'}" : "Pay-Date: ${eventDate ?? 'N/A'}",
                  style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${event.stockName} • ${event.sharesOwned.toStringAsFixed(1)} shares",
                  style: theme.subtitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Payout details
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                event.currency == "CAD"
                    ? "\$${event.projectedPayout.toStringAsFixed(2)}"
                    : "${event.currency}\$${event.projectedPayout.toStringAsFixed(2)}",
                style: theme.cardTitleStyle.copyWith(color: AppColors.positive, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "\$${event.amountPerShare.toStringAsFixed(2)}/sh",
                style: theme.subtitleStyle,
              ),
              if (isAapl && isExDiv)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Ex-Div Alert",
                    style: TextStyle(color: Color(0xFFFFB300), fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Agenda List View Mode
  Widget _buildAgendaListView(ThemeProvider theme) {
    if (_viewModel.calendarEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text("No upcoming dividend payments found", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upcoming Agenda Schedule", style: theme.cardTitleStyle.copyWith(fontSize: 15)),
        const SizedBox(height: 12),
        ..._viewModel.calendarEvents.map((event) {
          return _buildCalendarEventCard(theme, event, isExDiv: false);
        }),
      ],
    );
  }

  // 4. Settings Tab
  Widget _buildSettingsTab(ThemeProvider theme) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Text("Settings", style: theme.titleStyle),
        Text("Manage your preferences and theme options.", style: theme.subtitleStyle),
        const SizedBox(height: 24),

        // Theme Customization Card
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
              Text(
                "Theme Preferences",
                style: theme.cardTitleStyle.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                "Switch between dark and light appearance.",
                style: theme.subtitleStyle,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        theme.isDark ? "🌙" : "☀️",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Dark Mode",
                        style: theme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Switch(
                    value: theme.isDark,
                    activeTrackColor: AppColors.positive.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.positive,
                    onChanged: (_) => theme.toggleTheme(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // App Information Card
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
              Text(
                "App Info",
                style: theme.cardTitleStyle.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Version", style: theme.subtitleStyle),
                  Text("1.0.0", style: theme.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Environment", style: theme.subtitleStyle),
                  Text("Hybrid / Mock Fallback", style: theme.bodyStyle.copyWith(color: AppColors.positive, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. History Tab (Transactions Ledger Table)
  Widget _buildHistoryTab(ThemeProvider theme) {
    final transactions = _viewModel.filteredTransactions;

    return RefreshIndicator(
      onRefresh: () async {
        await _viewModel.loadTransactions();
      },
      color: AppColors.positive,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Transactions Ledger", style: theme.titleStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text("Complete record of buys & sells", style: theme.subtitleStyle),
                ],
              ),
              InkWell(
                onTap: () => _viewModel.loadTransactions(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.border),
                  ),
                  child: Text("🔄", style: TextStyle(color: theme.text, fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Box
                TextField(
                  onChanged: (val) => _viewModel.setHistorySearchQuery(val),
                  style: TextStyle(color: theme.text, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Filter by ticker symbol or company...",
                    hintStyle: TextStyle(color: theme.subtext, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: theme.subtext, size: 18),
                    filled: true,
                    fillColor: theme.isDark ? const Color(0xFF181B20) : const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // Type Filter Badges (ALL / BUY / SELL)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text("Type: ", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 8),
                      _buildFilterBadge("All", "ALL", _viewModel.historyTypeFilter, (type) => _viewModel.setHistoryTypeFilter(type), theme),
                      const SizedBox(width: 6),
                      _buildFilterBadge("BUY Only", "BUY", _viewModel.historyTypeFilter, (type) => _viewModel.setHistoryTypeFilter(type), theme, activeColor: AppColors.positive),
                      const SizedBox(width: 6),
                      _buildFilterBadge("SELL Only", "SELL", _viewModel.historyTypeFilter, (type) => _viewModel.setHistoryTypeFilter(type), theme, activeColor: AppColors.negative),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Account Filter Badges
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text("Account: ", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 8),
                      _buildFilterBadge("All Accounts", "ALL", _viewModel.historyProfileFilter, (id) => _viewModel.setHistoryProfileFilter(id), theme),
                      ..._viewModel.profiles.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: _buildFilterBadge(p.type, p.id, _viewModel.historyProfileFilter, (id) => _viewModel.setHistoryProfileFilter(id), theme),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Transactions Table
          if (_viewModel.isLoadingTransactions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.positive)),
            )
          else if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.border),
              ),
              child: const Center(
                child: Text("No transactions match the selected filters", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  headingRowHeight: 44,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  columns: [
                    DataColumn(label: Text("Date", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Type", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Asset", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Account", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Shares", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Price", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Total Value", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold))),
                  ],
                  rows: transactions.map((tx) {
                    final isBuy = tx.type == "BUY";
                    return DataRow(
                      cells: [
                        DataCell(Text(tx.date, style: TextStyle(color: theme.text, fontSize: 12, fontWeight: FontWeight.w600))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isBuy ? AppColors.positive : AppColors.negative).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isBuy ? AppColors.positive : AppColors.negative, width: 0.8),
                            ),
                            child: Text(
                              tx.type,
                              style: TextStyle(
                                color: isBuy ? AppColors.positive : AppColors.negative,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.ticker, style: theme.cardTitleStyle.copyWith(fontSize: 13)),
                              Text(tx.stockName, style: theme.subtitleStyle.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        DataCell(Text(tx.profileName, style: theme.subtitleStyle.copyWith(fontSize: 11))),
                        DataCell(Text(tx.shares.toStringAsFixed(1), style: TextStyle(color: theme.text, fontSize: 12, fontWeight: FontWeight.bold))),
                        DataCell(Text("\$${tx.price.toStringAsFixed(2)} ${tx.currency}", style: theme.subtitleStyle.copyWith(fontSize: 11))),
                        DataCell(
                          Text(
                            "\$${tx.totalAmount.toStringAsFixed(2)} ${tx.currency}",
                            style: TextStyle(
                              color: isBuy ? theme.text : AppColors.positive,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(
    String label,
    String value,
    String activeValue,
    Function(String) onTap,
    ThemeProvider theme, {
    Color? activeColor,
  }) {
    final isActive = activeValue == value;
    final color = activeColor ?? AppColors.positive;

    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : theme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : theme.subtext,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // 2. Dedicated Dividend Tab (Expected Dividend Projections with Sliding Windows)
  Widget _buildDividendTab(ThemeProvider theme) {
    final totalDivCAD = _viewModel.currentSelectedDividendAmount;

    return RefreshIndicator(
      onRefresh: () async {
        await _viewModel.loadDividendTab();
        await _viewModel.loadReceivedDividends();
      },
      color: AppColors.positive,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: theme.text),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dividend Income", style: theme.titleStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
                      Text("Track projected vs actual income", style: theme.subtitleStyle),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  _viewModel.loadDividendTab();
                  _viewModel.loadReceivedDividends();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.border),
                  ),
                  child: Text("🔄", style: TextStyle(color: theme.text, fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Button: Log Dividend Payment
          InkWell(
            onTap: () => _showLogDividendSheet(theme),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.positive,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.positive.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text("Log Dividend Received", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Profile Filter Selector Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterBadge("All Combined", "ALL", _viewModel.dividendProfileId, (id) => _viewModel.setDividendProfileId(id), theme, activeColor: AppColors.positive),
                ..._viewModel.profiles.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: _buildFilterBadge(p.name, p.id, _viewModel.dividendProfileId, (id) => _viewModel.setDividendProfileId(id), theme, activeColor: AppColors.positive),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary Metrics Cards (Projected vs Actual)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.border, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Projected (Annual)", style: theme.subtitleStyle.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        "\$${totalDivCAD.toStringAsFixed(0)}",
                        style: theme.cardTitleStyle.copyWith(fontSize: 22, color: AppColors.positive),
                      ),
                      const SizedBox(height: 4),
                      Text("Yield: ${(totalDivCAD > 0 ? (totalDivCAD / (_viewModel.totalValuationCAD > 0 ? _viewModel.totalValuationCAD : 1) * 100) : 0).toStringAsFixed(2)}%", style: theme.subtitleStyle.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.positive.withValues(alpha: 0.3), width: 1.5),
                    color: AppColors.positive.withValues(alpha: 0.05),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Actual YTD", style: theme.subtitleStyle.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.positive)),
                      const SizedBox(height: 8),
                      Text(
                        "\$${_viewModel.currentYearReceived.toStringAsFixed(0)}",
                        style: theme.cardTitleStyle.copyWith(fontSize: 22, color: AppColors.positive),
                      ),
                      const SizedBox(height: 4),
                      Text("All-Time: \$${_viewModel.totalReceivedAllTime.toStringAsFixed(0)}", style: theme.subtitleStyle.copyWith(fontSize: 10, color: AppColors.positive.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sliding Window Expected Dividend Line Chart
          Text(
            "Projected Income Trend",
            style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          ModernHistoryChart(points: _viewModel.dividendChartPoints),
          const SizedBox(height: 14),

          // Sliding Window Selector (1W, 6M, 1Y, ALL)
          Container(
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.border, width: 1.5),
            ),
            child: Row(
              children: ["1W", "6M", "1Y", "ALL"].map((interval) {
                final isActive = _viewModel.activeDividendInterval == interval;
                String label = interval;
                if (interval == "1W") label = "1 Week";
                if (interval == "6M") label = "6 Months";
                if (interval == "1Y") label = "1 Year";
                if (interval == "ALL") label = "ALL";

                return Expanded(
                  child: InkWell(
                    onTap: () => _viewModel.setActiveDividendInterval(interval),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.positive : Colors.transparent,
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
          ),
          const SizedBox(height: 24),

          // Dividend Action Buttons
          Row(
            children: [
              Expanded(
                child: HoverButton(
                  label: "Analytics",
                  icon: Icons.pie_chart,
                  onTap: () => context.push('/dividend-analytics?id=${_viewModel.dividendProfileId}'),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HoverButton(
                  label: "Objective",
                  icon: Icons.local_fire_department,
                  onTap: () => setState(() => _currentTabIndex = 2),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HoverButton(
                  label: "Calendar",
                  icon: Icons.calendar_month,
                  onTap: () => setState(() => _currentTabIndex = 3),
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Expected Dividend Contributors List
          Text(
            "My Holdings",
            style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),

          ..._buildDividendStocksList(theme),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  List<Widget> _buildDividendStocksList(ThemeProvider theme) {
    List<StockHolding> stocks = [];
    if (_viewModel.dividendProfileId == "ALL") {
      for (var p in _viewModel.profiles) {
        stocks.addAll(p.stocks);
      }
    } else {
      final p = _viewModel.selectedDividendProfile;
      if (p != null) stocks = p.stocks;
    }

    // Deduplicate stocks by ticker if we're showing ALL
    final Map<String, StockHolding> uniqueStocks = {};
    for (var s in stocks) {
      if (uniqueStocks.containsKey(s.ticker)) {
        final existing = uniqueStocks[s.ticker]!;
        uniqueStocks[s.ticker] = StockHolding(
          stockId: existing.stockId,
          ticker: existing.ticker,
          name: existing.name,
          shares: existing.shares + s.shares,
          price: existing.price,
          change: existing.change,
          changePercent: existing.changePercent,
          currency: existing.currency,
          value: existing.value + s.value,
        );
      } else {
        uniqueStocks[s.ticker] = s;
      }
    }
    
    stocks = uniqueStocks.values.toList();
    stocks.sort((a, b) => b.value.compareTo(a.value)); // Sort by total value

    if (stocks.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.border)),
          child: const Center(child: Text("No dividend-paying stocks in this profile", style: TextStyle(color: Colors.grey))),
        )
      ];
    }

    return stocks.map((stock) {
      final estPayout = stock.shares * 0.75; // Using mock logic temporarily
      final yoc = (estPayout * 4 / stock.value) * 100; // Mock YOC calculation
      
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.border, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.positive.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text("💰", style: TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(stock.ticker, style: theme.cardTitleStyle.copyWith(fontSize: 14)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.positive.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text("YOC ${yoc.toStringAsFixed(1)}%", style: TextStyle(color: AppColors.positive, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text(stock.name, style: theme.subtitleStyle.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Est. \$${(estPayout * 4).toStringAsFixed(2)} ${stock.currency} /yr",
                  style: theme.cardTitleStyle.copyWith(color: AppColors.positive, fontSize: 13),
                ),
                Row(
                  children: [
                    Text("${stock.shares} shs", style: theme.subtitleStyle.copyWith(fontSize: 10)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showEditDividendSheet(theme, stock),
                      child: Text("Edit Div", style: theme.subtitleStyle.copyWith(fontSize: 10, color: AppColors.positive, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
  void _showLogDividendSheet(ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Log Dividend Received", style: theme.titleStyle.copyWith(fontSize: 20)),
              const SizedBox(height: 16),
              Text("Select Stock and Amount", style: theme.subtitleStyle),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Save Log"),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showEditDividendSheet(ThemeProvider theme, StockHolding stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit Dividend for ${stock.ticker}", style: theme.titleStyle.copyWith(fontSize: 20)),
              const SizedBox(height: 16),
              Text("Current Estimated: \$${(stock.shares * 0.75 * 4).toStringAsFixed(2)} / yr", style: theme.subtitleStyle),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Save Changes"),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}


