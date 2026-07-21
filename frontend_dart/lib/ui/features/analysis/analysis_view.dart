import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';
import '../profile/profile_view.dart'; // To reuse DonutChartItem and colors

// Helper metadata mapper
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

class AnalysisViewModel extends ChangeNotifier {
  final ApiService apiService;
  final String profileId;
  final String type; // "stock" | "sector" | "dividend"

  List<DonutChartItem> _items = [];
  double _totalValue = 0;
  bool _isLoading = true;
  String _title = "Portfolio Analysis";

  AnalysisViewModel({
    required this.apiService,
    required this.profileId,
    required this.type,
  });

  List<DonutChartItem> get items => _items;
  double get totalValue => _totalValue;
  bool get isLoading => _isLoading;
  String get title => _title;

  Future<void> calculateAllocations() async {
    try {
      final profile = await apiService.getProfileDetail(profileId);
      final List<Color> colorsList = [
        const Color(0xFF4CAF50),
        const Color(0xFF2196F3),
        const Color(0xFF9C27B0),
        const Color(0xFFFF9800),
        const Color(0xFFE91E63),
        const Color(0xFF00BCD4),
        const Color(0xFF8BC34A),
        const Color(0xFF3F51B5),
      ];

      if (type == "stock") {
        _title = "Stock Weight Details";
        _totalValue = profile.stocks.fold(
          0.0,
          (acc, s) => acc + apiService.convertCurrencyToCAD(s.value, s.currency),
        );
        _items = profile.stocks.map((s) {
          final valCAD = apiService.convertCurrencyToCAD(s.value, s.currency);
          return DonutChartItem(
            key: s.ticker,
            label: s.ticker,
            value: valCAD,
            percentage: _totalValue > 0 ? valCAD / _totalValue : 0,
          );
        }).toList();
      } else if (type == "sector") {
        _title = "Sector Exposure Details";
        final Map<String, double> sectors = {};
        for (var s in profile.stocks) {
          final meta = _getStockMetadata(s.ticker);
          final valCAD = apiService.convertCurrencyToCAD(s.value, s.currency);
          final sector = meta["sector"] as String;
          sectors[sector] = (sectors[sector] ?? 0.0) + valCAD;
        }
        _totalValue = sectors.values.fold(0.0, (a, b) => a + b);
        _items = sectors.keys.map((sector) {
          return DonutChartItem(
            key: sector,
            label: sector,
            value: sectors[sector]!,
            percentage: _totalValue > 0 ? sectors[sector]! / _totalValue : 0,
          );
        }).toList();
      } else if (type == "dividend") {
        _title = "Dividend Contributions";
        final contributions = profile.stocks.map((s) {
          final meta = _getStockMetadata(s.ticker);
          final valCAD = apiService.convertCurrencyToCAD(s.value, s.currency);
          final divYield = meta["dividendYield"] as double;
          final divAnnual = valCAD * divYield;
          return {
            "ticker": s.ticker,
            "divAnnual": divAnnual,
          };
        }).toList();

        _totalValue = contributions.fold(0.0, (acc, val) => acc + (val["divAnnual"] as double));
        _items = contributions.map((c) {
          final ticker = c["ticker"] as String;
          final divVal = c["divAnnual"] as double;
          return DonutChartItem(
            key: ticker,
            label: ticker,
            value: divVal,
            percentage: _totalValue > 0 ? divVal / _totalValue : 0,
          );
        }).toList();
      }

      // Sort items by size
      _items.sort((a, b) => b.value.compareTo(a.value));

      // Color items
      for (int i = 0; i < _items.length; i++) {
        _items[i].color = colorsList[i % colorsList.length];
      }
    } catch (e) {
      debugPrint("Error calculating allocations: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class AnalysisView extends StatefulWidget {
  final String profileId;
  final String type;

  const AnalysisView({
    super.key,
    required this.profileId,
    required this.type,
  });

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  late AnalysisViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _viewModel = AnalysisViewModel(
      apiService: apiService,
      profileId: widget.profileId,
      type: widget.type,
    );
    Future.microtask(() => _viewModel.calculateAllocations());
  }

  String formatCurrency(double amount) {
    return "\$${amount.toStringAsFixed(2)}";
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
            Text(_viewModel.title, style: theme.cardTitleStyle.copyWith(fontSize: 18)),
            const Text("Allocation weight breakdown analysis", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            if (_viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.positive));
            }

            return ListView.builder(
              itemCount: _viewModel.items.length + 1,
              padding: const EdgeInsets.all(20.0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Large centered Donut chart in header
                  return Container(
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 32),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(170, 170),
                            painter: _LargeDonutPainter(
                              items: _viewModel.items,
                              isDark: theme.isDark,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Total Allocation",
                                style: theme.subtitleStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(_viewModel.totalValue),
                                style: theme.cardTitleStyle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Breakdown rows
                final item = _viewModel.items[index - 1];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Color indicator dot
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Ticker / label
                      Expanded(
                        child: Text(
                          item.label,
                          style: theme.cardTitleStyle.copyWith(fontSize: 14),
                        ),
                      ),
                      // Value + percentage weight
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatCurrency(item.value), style: theme.cardTitleStyle.copyWith(fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            "${(item.percentage * 100).toStringAsFixed(1)}%",
                            style: TextStyle(color: theme.subtext, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LargeDonutPainter extends CustomPainter {
  final List<DonutChartItem> items;
  final bool isDark;

  _LargeDonutPainter({required this.items, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double innerRadius = radius - 18.0; // Stroke width 18

    // Draw background path placeholder
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF222429) : const Color(0xFFE5E7EB)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, innerRadius, bgPaint);

    double startAngle = -math.pi / 2;

    for (var item in items) {
      final double sweepAngle = 2 * math.pi * item.percentage;
      if (sweepAngle == 0) continue;

      final arcPaint = Paint()
        ..color = item.color
        ..strokeWidth = 17
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle - 0.03, // gap spacing
        false,
        arcPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _LargeDonutPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.isDark != isDark;
  }
}
