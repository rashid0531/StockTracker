import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/profile.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';

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

  DashboardViewModel({required this.apiService});

  List<InvestmentProfile> get profiles => _profiles;
  bool get isLoading => _isLoading;

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

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profiles = await apiService.getProfiles();
    } catch (e) {
      debugPrint("Error loading dashboard: $e");
    } finally {
      _isLoading = false;
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
  late DashboardViewModel _viewModel;
  int _currentTabIndex = 0;

  // FIRE Milestones State (locally customizable)
  double _coffeeCost = 100.0;
  double _utilityCost = 300.0;
  double _housingCost = 2000.0;
  double _fireCost = 4000.0;

  // Dividend Calendar State
  List<DividendCalendarEvent> _calendarEvents = [];
  bool _loadingCalendar = false;
  DateTime _focusedMonth = DateTime(2026, 7, 1);
  DateTime? _selectedDate = DateTime(2026, 7, 28);
  bool _isCalendarGridView = true;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _viewModel = DashboardViewModel(apiService: apiService);
    Future.microtask(() async {
      await _viewModel.loadDashboard();
      await _loadCalendar();
    });
  }

  Future<void> _loadCalendar() async {
    setState(() => _loadingCalendar = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final events = await apiService.getDividendCalendar(ApiService.mockUserId);
      setState(() {
        _calendarEvents = events;
      });
    } catch (e) {
      debugPrint("Error loading calendar: $e");
    } finally {
      setState(() => _loadingCalendar = false);
    }
  }

  String formatCAD(double val) {
    return "\$${val.toStringAsFixed(2)}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
          if (index == 2) {
            _loadCalendar();
          }
        },
        backgroundColor: theme.card,
        selectedItemColor: AppColors.positive,
        unselectedItemColor: theme.subtext,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Text("📊", style: TextStyle(fontSize: 18)),
            activeIcon: Text("📊", style: TextStyle(fontSize: 18)),
            label: "Portfolio",
          ),
          BottomNavigationBarItem(
            icon: Text("🔥", style: TextStyle(fontSize: 18)),
            activeIcon: Text("🔥", style: TextStyle(fontSize: 18)),
            label: "FIRE",
          ),
          BottomNavigationBarItem(
            icon: Text("📅", style: TextStyle(fontSize: 18)),
            activeIcon: Text("📅", style: TextStyle(fontSize: 18)),
            label: "Calendar",
          ),
          BottomNavigationBarItem(
            icon: Text("⚙️", style: TextStyle(fontSize: 18)),
            activeIcon: Text("⚙️", style: TextStyle(fontSize: 18)),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeProvider theme) {
    switch (_currentTabIndex) {
      case 1:
        return _buildFireTab(theme);
      case 2:
        return _buildCalendarTab(theme);
      case 3:
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
        await _loadCalendar();
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
                      Text("SoloRash Net Worth", style: theme.titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w900)),
                      Text("StockTracker by SoloRash", style: theme.subtitleStyle.copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => context.push("/import"),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.border),
                  ),
                  child: Text(
                    "➕",
                    style: TextStyle(color: theme.text, fontSize: 16),
                  ),
                ),
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
                const SizedBox(height: 20),
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
          Text(
            "Investment Profiles",
            style: theme.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
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
        Text("FIRE Milestones", style: theme.titleStyle),
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

        _buildMilestoneProgressCard("☕ Level 1: Coffee & Snacks", monthlyDividend, _coffeeCost, theme, (newVal) {
          setState(() => _coffeeCost = newVal);
        }),
        _buildMilestoneProgressCard("🔌 Level 2: Utilities & Phone", monthlyDividend, _utilityCost, theme, (newVal) {
          setState(() => _utilityCost = newVal);
        }),
        _buildMilestoneProgressCard("🏠 Level 3: Housing & Rent", monthlyDividend, _housingCost, theme, (newVal) {
          setState(() => _housingCost = newVal);
        }),
        _buildMilestoneProgressCard("🚀 Level 4: Lean FIRE Goals", monthlyDividend, _fireCost, theme, (newVal) {
          setState(() => _fireCost = newVal);
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
    if (_loadingCalendar) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.positive),
      );
    }

    final hasUpcomingExDiv = _calendarEvents.any((e) => e.ticker == "AAPL");

    return RefreshIndicator(
      onRefresh: _loadCalendar,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dividend Calendar", style: theme.titleStyle),
                    Text("Chronological schedule of ex-dividend dates and payments.", style: theme.subtitleStyle),
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
                  final exEvents = _calendarEvents.where((e) => e.exDividendDate == dateStr).toList();
                  final payEvents = _calendarEvents.where((e) => e.paymentDate == dateStr).toList();
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

    final dateExEvents = _calendarEvents.where((e) => e.exDividendDate == dateStr).toList();
    final datePayEvents = _calendarEvents.where((e) => e.paymentDate == dateStr).toList();
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
    final monthEvents = _calendarEvents.where((e) {
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
    if (_calendarEvents.isEmpty) {
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
        ..._calendarEvents.map((event) {
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
}
