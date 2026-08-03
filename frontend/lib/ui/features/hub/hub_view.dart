import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../../core/providers/pillar_preferences_provider.dart';

class HubView extends StatelessWidget {
  const HubView({super.key});

  static void showPillarCustomizationDialog(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Consumer<PillarPreferencesProvider>(
          builder: (context, prefs, child) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "⚙️ Customize Active Pillars",
                        style: theme.cardTitleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: theme.subtext),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Enable or disable modular pillars. Your balance sheet and navigation will react instantly.",
                    style: theme.subtitleStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  _buildPillarToggle(
                    theme: theme,
                    title: "📈 Stocks & Equities",
                    subtitle: "Portfolios, Dividends, Buy/Sell Ledger & FIRE targets",
                    color: AppColors.positive,
                    value: prefs.isStocksEnabled,
                    onChanged: (val) => prefs.togglePillar("Stocks", val),
                  ),
                  const SizedBox(height: 12),

                  _buildPillarToggle(
                    theme: theme,
                    title: "🏠 Real-Estate Property",
                    subtitle: "Valuation, Mortgages, Net Equity & Rental Cashflow",
                    color: const Color(0xFF3B82F6),
                    value: prefs.isRealEstateEnabled,
                    onChanged: (val) => prefs.togglePillar("Real-Estate", val),
                  ),
                  const SizedBox(height: 12),

                  _buildPillarToggle(
                    theme: theme,
                    title: "🥇 Precious Metals Vault",
                    subtitle: "Physical Gold, Silver, Platinum & Bronze holdings",
                    color: const Color(0xFFF59E0B),
                    value: prefs.isPreciousMetalsEnabled,
                    onChanged: (val) => prefs.togglePillar("Precious Metals", val),
                  ),
                  const SizedBox(height: 12),

                  _buildPillarToggle(
                    theme: theme,
                    title: "❤️ Health & Wellness Log",
                    subtitle: "Weight, Resting HR, Sleep Score & Daily Vitality Index",
                    color: const Color(0xFFEC4899),
                    value: prefs.isHealthEnabled,
                    onChanged: (val) => prefs.togglePillar("Health", val),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildPillarToggle({
    required ThemeProvider theme,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.12) : theme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: value ? color : theme.border, width: value ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.cardTitleStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.subtitleStyle.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: color.withValues(alpha: 0.5),
            activeThumbColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final prefs = Provider.of<PillarPreferencesProvider>(context);
    final isWide = MediaQuery.of(context).size.width >= 800;

    final List<Map<String, dynamic>> allSections = [
      {
        "key": "Stocks",
        "title": "Stocks & Equities",
        "subtitle": "Portfolios, Buy/Sell ledger, Dividends, FIRE target",
        "icon": "📈",
        "route": "/stocks",
        "badge": "Active",
        "color": AppColors.positive,
      },
      {
        "key": "Real-Estate",
        "title": "Real-Estate",
        "subtitle": "Residential, Commercial, Net Equity & Monthly Cashflow",
        "icon": "🏠",
        "route": "/real-estate",
        "badge": "2 Properties",
        "color": const Color(0xFF3B82F6),
      },
      {
        "key": "Precious Metals",
        "title": "Precious Metals",
        "subtitle": "Physical Gold, Silver, Platinum, Bronze vault holdings",
        "icon": "🥇",
        "route": "/precious-metals",
        "badge": "310 oz",
        "color": const Color(0xFFF59E0B),
      },
      {
        "key": "Health",
        "title": "Health & Wellness",
        "subtitle": "Body Weight, Resting HR, Sleep Quality, Daily Score",
        "icon": "❤️",
        "route": "/health",
        "badge": "Optimal",
        "color": const Color(0xFFEC4899),
      },
    ];

    final activeSections = allSections.where((sec) => prefs.isPillarEnabled(sec["key"] as String)).toList();

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
                      IconButton(
                        icon: Icon(Icons.tune_rounded, color: theme.text),
                        onPressed: () => showPillarCustomizationDialog(context),
                        tooltip: "Customize Active Pillars",
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.positive,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () => context.push("/create-asset"),
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        label: const Text("New Asset", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 6),
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
                          child: Text("${prefs.activePillarCount} PILLARS ACTIVE", style: const TextStyle(color: AppColors.positive, fontWeight: FontWeight.w900, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "\$1,985,420.00 CAD",
                      style: theme.cardTitleStyle.copyWith(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.positive),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _buildActiveBreakdownString(prefs),
                      style: theme.subtitleStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Explore Asset & Life Pillars", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  InkWell(
                    onTap: () => showPillarCustomizationDialog(context),
                    child: Text("⚙️ Configure Pillars", style: TextStyle(color: AppColors.positive, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (activeSections.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.border),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Text("🧩 All Pillars Disabled", style: theme.cardTitleStyle.copyWith(fontSize: 16)),
                        const SizedBox(height: 6),
                        Text("Tap 'Configure Pillars' above to activate Stocks, Real Estate, Metals, or Health.", style: theme.subtitleStyle),
                      ],
                    ),
                  ),
                )
              else if (isWide)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: activeSections.length,
                  itemBuilder: (context, index) => _buildSectionCard(activeSections[index], theme, context),
                )
              else
                Column(
                  children: activeSections.map((sec) => Padding(
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

  String _buildActiveBreakdownString(PillarPreferencesProvider prefs) {
    final List<String> items = [];
    if (prefs.isStocksEnabled) items.add("Stocks: \$95.4k");
    if (prefs.isRealEstateEnabled) items.add("Real Estate Equity: \$1.01M");
    if (prefs.isPreciousMetalsEnabled) items.add("Metals: \$31.8k");
    if (prefs.isHealthEnabled) items.add("Health Score: 92/100");
    return items.isEmpty ? "No active pillars enabled" : items.join(" • ");
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
