import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../profile_view.dart'; // To get DonutChartItem

class ModernGridDonutCard extends StatefulWidget {
  final List<DonutChartItem> items;
  final String title;
  final String subtitle;
  final String centerLabel;
  final VoidCallback onPress;

  const ModernGridDonutCard({
    super.key,
    required this.items,
    required this.title,
    required this.subtitle,
    required this.centerLabel,
    required this.onPress,
  });

  @override
  State<ModernGridDonutCard> createState() => _ModernGridDonutCardState();
}

class _ModernGridDonutCardState extends State<ModernGridDonutCard> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final hasData = widget.items.any((i) => i.value > 0);

    return InkWell(
      onTap: widget.onPress,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: theme.subtext),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              style: TextStyle(color: theme.subtext, fontSize: 11),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: Stack(
                children: [
                  if (hasData)
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: showingSections(theme),
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        "No data",
                        style: TextStyle(color: theme.subtext, fontSize: 12),
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.centerLabel,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (touchedIndex != -1 && touchedIndex < widget.items.length)
                          Text(
                            "${(widget.items[touchedIndex].percentage * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              color: theme.subtext,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections(ThemeProvider theme) {
    return List.generate(widget.items.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 20.0 : 15.0;
      final item = widget.items[i];

      return PieChartSectionData(
        color: item.color,
        value: item.value,
        title: '${(item.percentage * 100).toStringAsFixed(0)}%',
        radius: radius,
        showTitle: false, // Don't show text inside slices because it clutters the small card
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: item.color),
                ),
                child: Text(
                  item.label,
                  style: TextStyle(color: theme.text, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    });
  }
}
