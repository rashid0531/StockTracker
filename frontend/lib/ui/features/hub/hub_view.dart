import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class HubView extends StatelessWidget {
  const HubView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isWide = MediaQuery.of(context).size.width >= 800;

    final List<Map<String, dynamic>> sections = [
      {
        "title": "Stocks & Equities",
        "subtitle": "Portfolios, Buy/Sell ledger, Dividends, FIRE target",
        "icon": "📈",
        "route": "/stocks",
        "badge": "Active",
        "color": AppColors.positive,
      },
      {
        "title": "Real-Estate",
        "subtitle": "Residential, Commercial, Net Equity & Monthly Cashflow",
        "icon": "🏠",
        "route": "/real-estate",
        "badge": "2 Properties",
        "color": const Color(0xFF3B82F6),
      },
      {
        "title": "Precious Metals",
        "subtitle": "Physical Gold, Silver, Platinum, Bronze vault holdings",
        "icon": "🥇",
        "route": "/precious-metals",
        "badge": "310 oz",
        "color": const Color(0xFFF59E0B),
      },
      {
        "title": "Health & Wellness",
        "subtitle": "Body Weight, Resting HR, Sleep Quality, Daily Score",
        "icon": "❤️",
        "route": "/health",
        "badge": "Optimal",
        "color": const Color(0xFFEC4899),
      },
    ];

    return Scaffold(
      backgroundColor: theme.bg,
      body: theme.buildBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
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
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/solorash_logo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Text("⚡", style: TextStyle(fontSize: 22)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Wealth & Life Hub", style: theme.titleStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w900)),
                          Text("Solo Rash • Total Wealth Dashboard", style: theme.subtitleStyle),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.positive,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () => context.push("/create-asset"),
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        label: const Text("New Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(theme.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: theme.text),
                        onPressed: () => theme.toggleTheme(),
                        tooltip: "Toggle Theme",
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Total Estimated Net Worth Banner Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.border, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ESTIMATED COMBINED NET WORTH", style: theme.subtitleStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.positive.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text("4 PILLARS ACTIVE", style: TextStyle(color: AppColors.positive, fontWeight: FontWeight.w900, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "\$1,985,420.00 CAD",
                      style: theme.cardTitleStyle.copyWith(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.positive),
                    ),
                    const SizedBox(height: 8),
                    Text("Stocks: \$95.4k • Real Estate Equity: \$1.01M • Metals: \$31.8k • Health Score: 92/100", style: theme.subtitleStyle.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text("Explore Asset & Life Pillars", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 16),

              // Grid / List of Section Cards
              if (isWide)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: sections.length,
                  itemBuilder: (context, index) => _buildSectionCard(sections[index], theme, context),
                )
              else
                Column(
                  children: sections.map((sec) => Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: _buildSectionCard(sec, theme, context),
                  )).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(Map<String, dynamic> sec, ThemeProvider theme, BuildContext context) {
    final Color color = sec["color"] as Color;

    return InkWell(
      onTap: () => context.push(sec["route"] as String),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.border, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(sec["icon"] as String, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sec["title"] as String, style: theme.cardTitleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(sec["badge"] as String, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sec["subtitle"] as String,
                    style: theme.subtitleStyle.copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: theme.subtext, size: 24),
          ],
        ),
      ),
    );
  }
}
