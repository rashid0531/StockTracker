import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';

class DividendSuggestionView extends StatelessWidget {
  const DividendSuggestionView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Portfolio Suggestions",
          style: theme.titleStyle.copyWith(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AI Portfolio Analysis",
              style: theme.titleStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "We analyze your holdings to ensure maximum stability and growth.",
              style: theme.subtitleStyle,
            ),
            const SizedBox(height: 32),
            
            // Stability Section
            _buildMetricCard(
              theme: theme,
              title: "Dividend Stability Score",
              subtitle: "Analyzed via rate-cut prediction ML model (Beta)",
              score: "78/100",
              scoreColor: Colors.orange,
              progress: 0.78,
              description: "Your portfolio has moderate exposure to future rate cuts. Certain REITs and Utilities might be impacted if interest rates remain high. Consider diversifying into consumer staples.",
              icon: Icons.shield_outlined,
            ),
            
            const SizedBox(height: 24),
            
            // Balance Section
            _buildMetricCard(
              theme: theme,
              title: "Portfolio Balance Meter",
              subtitle: "Income vs. Capital Growth",
              score: "Yield Heavy",
              scoreColor: Colors.blue,
              progress: 0.85,
              description: "Your portfolio leans heavily towards high-yield sectors (telecom, banking). While this guarantees stable dividends, you may be sacrificing long-term capital growth. Consider adding growth-oriented dividend payers (e.g., tech, healthcare).",
              icon: Icons.balance,
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Prediction models are for informational purposes only.",
                style: theme.subtitleStyle.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricCard({
    required ThemeProvider theme,
    required String title,
    required String subtitle,
    required String score,
    required Color scoreColor,
    required double progress,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scoreColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.titleStyle.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.subtitleStyle.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Current Status", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
              Text(score, style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.border,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(color: theme.text.withOpacity(0.8), height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
