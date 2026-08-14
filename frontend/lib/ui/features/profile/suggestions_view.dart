import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';

class SuggestionsView extends StatelessWidget {
  final String profileId;

  const SuggestionsView({
    Key? key,
    required this.profileId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.card,
        elevation: 0,
        title: Text(
          "AI Portfolio Suggestions",
          style: theme.titleStyle.copyWith(fontSize: 18),
        ),
        iconTheme: IconThemeData(color: theme.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard("Strongest Sector", "Technology", AppColors.positive, theme),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightCard("Weakest Sector", "Energy", AppColors.negative, theme),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Risk Mitigation Strategy", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    "Your portfolio is heavily weighted towards Technology stocks, making it vulnerable to sector-specific downturns. To mitigate future risk, consider diversifying into more defensive sectors such as Utilities or Consumer Staples, which tend to offer stable dividends and lower volatility during market corrections.",
                    style: theme.bodyStyle.copyWith(color: theme.subtext, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildInsightCard(String title, String value, Color color, ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.bodyStyle.copyWith(color: theme.subtext, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
