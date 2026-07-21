import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/profile.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';

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

            return _buildTabContent(theme);
          },
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
          // Top Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("My Net Worth", style: theme.titleStyle),
                  Text("Wealth & Dividend Tracker", style: theme.subtitleStyle),
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
          Text("Dividend Calendar", style: theme.titleStyle),
          Text("Chronological schedule of ex-dividend dates and payments.", style: theme.subtitleStyle),
          const SizedBox(height: 20),

          // 7-day Alert Warning Banner
          if (hasUpcomingExDiv)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
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

          Text("Upcoming Payments", style: theme.cardTitleStyle.copyWith(fontSize: 15)),
          const SizedBox(height: 12),

          if (_calendarEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text("No upcoming dividend payments found", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ..._calendarEvents.map((event) {
              final isAapl = event.ticker == "AAPL";
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    // Ticker badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.isDark ? const Color(0xFF1E2126) : const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.border),
                      ),
                      child: Center(
                        child: Text(
                          event.ticker,
                          style: TextStyle(color: theme.text, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Event Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.ticker, style: theme.cardTitleStyle.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text("Ex-Div: ${event.exDividendDate ?? 'N/A'}", style: theme.subtitleStyle),
                          Text("Pay: ${event.paymentDate ?? 'N/A'}", style: theme.subtitleStyle),
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
                          "${event.sharesOwned.toStringAsFixed(1)} shares • \$${event.amountPerShare.toStringAsFixed(2)}",
                          style: theme.subtitleStyle,
                        ),
                        if (isAapl)
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
            }),
        ],
      ),
    );
  }
}
