import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../../data/services/api_service.dart';

class AiSuggestionsView extends StatefulWidget {
  final String profileId;
  final ThemeProvider theme;

  const AiSuggestionsView({
    Key? key,
    required this.profileId,
    required this.theme,
  }) : super(key: key);

  @override
  State<AiSuggestionsView> createState() => _AiSuggestionsViewState();
}

class _AiSuggestionsViewState extends State<AiSuggestionsView> {
  bool _isLoading = true;
  bool _isPremium = true;
  Map<String, dynamic>? _suggestions;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    try {
      final suggestions = await ApiService().fetchAiSuggestions(widget.profileId);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
          _isPremium = true;
        });
      }
    } catch (e) {
      if (e.toString().contains("PAYMENT_REQUIRED")) {
        if (mounted) {
          setState(() {
            _isPremium = false;
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isPremium) {
      return _buildPaywall(widget.theme);
    }

    return _buildInsights(widget.theme);
  }

  Widget _buildPaywall(ThemeProvider theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Blurred background content
        Opacity(
          opacity: 0.3,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: _buildDummyInsights(theme),
          ),
        ),
        // Paywall Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividend, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.dividend.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: AppColors.dividend, size: 48),
              const SizedBox(height: 16),
              Text(
                "Unlock AI Insights",
                style: theme.titleStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Upgrade to premium to see how you can mitigate future risk and optimize your portfolio.",
                textAlign: TextAlign.center,
                style: theme.bodyStyle.copyWith(color: theme.subtext),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Simulate upgrading
                    ApiService().isPremium = true;
                    setState(() {
                      _isLoading = true;
                    });
                    _fetchSuggestions();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dividend,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Upgrade Now",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDummyInsights(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard("Strongest Sector", "████████", AppColors.positive, theme),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInsightCard("Weakest Sector", "██████", AppColors.negative, theme),
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
              const SizedBox(height: 8),
              Text(
                "██████████████████████████████████████████████████████████████████████████████████████████",
                style: theme.bodyStyle.copyWith(color: theme.subtext),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsights(ThemeProvider theme) {
    if (_suggestions == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard("Strongest Sector", _suggestions!["strongest_side"], AppColors.positive, theme),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInsightCard("Weakest Sector", _suggestions!["weakest_side"], AppColors.negative, theme),
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
              const SizedBox(height: 8),
              Text(
                _suggestions!["risk_mitigation"],
                style: theme.bodyStyle.copyWith(color: theme.subtext, height: 1.5),
              ),
            ],
          ),
        ),
      ],
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
