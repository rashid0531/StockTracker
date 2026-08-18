import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/profile.dart';
import '../../../core/theme.dart';

class ModernHistoryChart extends StatelessWidget {
  final List<ChartPoint> points;
  final bool showXAxis;

  const ModernHistoryChart({
    super.key, 
    required this.points,
    this.showXAxis = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    if (points.isEmpty) {
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

    final values = points.map((p) => p.value).toList();
    double maxY = values.reduce((a, b) => a > b ? a : b);
    double minY = values.reduce((a, b) => a < b ? a : b);
    if (maxY == minY) {
      maxY += 1;
      minY -= 1;
    }

    final double yRange = maxY - minY;
    maxY += yRange * 0.1; // Add 10% padding top
    minY -= yRange * 0.1; // Add 10% padding bottom
    if (minY < 0 && values.every((v) => v >= 0)) {
      minY = 0; // Don't go below zero if all values are positive
    }

    final formatCurrency = NumberFormat.simpleCurrency(decimalDigits: 0);

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 18, left: 6, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.isDark ? const Color(0xFF1E2838) : const Color(0xFFE2E8F0),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showXAxis,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  // Only show roughly 5-6 labels across the bottom
                  if (points.length > 10 && index % (points.length ~/ 5) != 0 && index != points.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      points[index].date,
                      style: TextStyle(color: theme.subtext, fontSize: 10),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: points.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.positive,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: points.length < 20, // Only show dots if there are few points
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.positive,
                    strokeWidth: 2,
                    strokeColor: theme.isDark ? const Color(0xFF0F172A) : Colors.white,
                  );
                }
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.positive.withValues(alpha: 0.3),
                    AppColors.positive.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => theme.isDark ? const Color(0xFF1E2838) : Colors.white,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final textStyle = TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  );
                  return LineTooltipItem(
                    formatCurrency.format(touchedSpot.y),
                    textStyle,
                    children: [
                      TextSpan(
                        text: '\n${points[touchedSpot.x.toInt()].date}',
                        style: TextStyle(
                          color: theme.subtext,
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                        ),
                      )
                    ]
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchLineEnd: (barData, spotIndex) => double.infinity,
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: theme.subtext.withValues(alpha: 0.3),
                    strokeWidth: 2,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: AppColors.positive,
                        strokeWidth: 3,
                        strokeColor: theme.isDark ? const Color(0xFF0F172A) : Colors.white,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
        duration: const Duration(milliseconds: 250), // Animation duration
        curve: Curves.easeInOut,
      ),
    );
  }
}
