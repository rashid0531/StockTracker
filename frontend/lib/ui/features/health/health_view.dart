import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/health_metric.dart';
import '../../../data/services/api_service.dart';
import '../../core/theme.dart';

class HealthView extends StatefulWidget {
  const HealthView({super.key});

  @override
  State<HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends State<HealthView> {
  final ApiService _apiService = ApiService();
  List<HealthMetricLog> _metrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getHealthMetrics();
      setState(() {
        _metrics = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddMetricModal() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final typeCtrl = TextEditingController(text: "Weight");
    final valCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: "kg");
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Log Health Metric ❤️", style: theme.cardTitleStyle.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: typeCtrl,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Metric Type (Weight, Sleep)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      style: TextStyle(color: theme.text),
                      decoration: InputDecoration(labelText: "Unit (kg, bpm, score)", labelStyle: TextStyle(color: theme.subtext)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Value", labelStyle: TextStyle(color: theme.subtext)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(labelText: "Notes (Optional)", labelStyle: TextStyle(color: theme.subtext)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (valCtrl.text.isEmpty) return;
                    final nav = Navigator.of(context);
                    await _apiService.addHealthMetric({
                      "metric_type": typeCtrl.text,
                      "value": double.tryParse(valCtrl.text) ?? 0.0,
                      "unit": unitCtrl.text,
                      "notes": notesCtrl.text,
                      "logged_at": "2026-07-30",
                    });
                    nav.pop();
                    _loadData();
                  },
                  child: const Text("Log Metric", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.text),
          onPressed: () => context.go('/hub'),
        ),
        title: Text("Health & Wellness Tracker ❤️", style: theme.cardTitleStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFEC4899)),
            onPressed: _showAddMetricModal,
          ),
        ],
      ),
      body: theme.buildBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
              : ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Wellness Index Banner Card
                    Container(
                      padding: const EdgeInsets.all(22),
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
                              Text("OVERALL WELLNESS INDEX", style: theme.subtitleStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFEC4899).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                child: const Text("EXCELLENT", style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "92 / 100",
                            style: theme.cardTitleStyle.copyWith(fontSize: 30, color: const Color(0xFFEC4899), fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildVitalsItem("Weight", "78.5 kg", theme),
                              _buildVitalsItem("Resting HR", "58 bpm", theme, color: AppColors.positive),
                              _buildVitalsItem("Sleep Score", "88 / 100", theme),
                              _buildVitalsItem("Body Fat", "14.2%", theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text("Recent Health Logs (${_metrics.length})", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    ..._metrics.map((hm) {
                      String icon = "📊";
                      if (hm.metricType.toLowerCase().contains("weight")) icon = "⚖️";
                      if (hm.metricType.toLowerCase().contains("hr") || hm.metricType.toLowerCase().contains("heart")) icon = "🫀";
                      if (hm.metricType.toLowerCase().contains("sleep")) icon = "😴";
                      if (hm.metricType.toLowerCase().contains("fat")) icon = "🔬";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(hm.metricType, style: theme.cardTitleStyle.copyWith(fontSize: 14)),
                                  if (hm.notes != null)
                                    Text(hm.notes!, style: theme.subtitleStyle.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(hm.formattedValue, style: theme.cardTitleStyle.copyWith(fontSize: 15, color: const Color(0xFFEC4899))),
                                Text(hm.loggedAt, style: theme.subtitleStyle.copyWith(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildVitalsItem(String label, String val, ThemeProvider theme, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.subtitleStyle.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: theme.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12, color: color ?? theme.text)),
      ],
    );
  }
}
