import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class ModuleSelectionView extends StatefulWidget {
  const ModuleSelectionView({super.key});

  @override
  State<ModuleSelectionView> createState() => _ModuleSelectionViewState();
}

class _ModuleSelectionViewState extends State<ModuleSelectionView> {
  final Map<String, bool> _modules = {
    "STOCKS": true, // Always start with Stocks selected
    "REAL_ESTATE": false,
    "BUSINESS": false,
    "HEALTH": false,
  };
  
  bool _isLoading = false;

  void _toggleModule(String module) {
    if (module == "STOCKS") return; // Keep stocks mandatory for now based on user feedback
    setState(() {
      _modules[module] = !_modules[module]!;
    });
  }

  Future<void> _saveSelection() async {
    setState(() => _isLoading = true);
    
    // In a real app we would call an API here to save user preferences:
    // await ApiService().updateUserModules(_modules.entries.where((e) => e.value).map((e) => e.key).toList());
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      context.go("/create-asset"); // Proceed to asset creation
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider(); // We'd ideally pull from context if using provider

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "What would you like to track?",
                style: theme.titleStyle.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 12),
              Text(
                "You can change this later. We'll customize your dashboard based on your selection.",
                style: theme.subtitleStyle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: ListView(
                  children: [
                    _buildModuleCard(
                      "STOCKS",
                      "Stocks & Dividends",
                      "Track portfolios, dividend yields, and performance.",
                      Icons.trending_up,
                      theme,
                    ),
                    const SizedBox(height: 16),
                    _buildModuleCard(
                      "REAL_ESTATE",
                      "Real Estate",
                      "Manage properties, rental income, and mortgages.",
                      Icons.home_work,
                      theme,
                    ),
                    const SizedBox(height: 16),
                    _buildModuleCard(
                      "BUSINESS",
                      "Business",
                      "Track private equity, startups, or side hustles.",
                      Icons.business_center,
                      theme,
                    ),
                    const SizedBox(height: 16),
                    _buildModuleCard(
                      "HEALTH",
                      "Health",
                      "Track metrics like weight, sleep, and heart rate.",
                      Icons.favorite,
                      theme,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.positive,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(String id, String title, String subtitle, IconData icon, ThemeProvider theme) {
    final isSelected = _modules[id] ?? false;
    final isMandatory = id == "STOCKS";
    
    return InkWell(
      onTap: isMandatory ? null : () => _toggleModule(id),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.positive.withValues(alpha: 0.1) : theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.positive : theme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.positive : theme.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.black : theme.text, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.cardTitleStyle.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.subtitleStyle),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.positive, size: 28)
            else
              Icon(Icons.circle_outlined, color: theme.border, size: 28),
          ],
        ),
      ),
    );
  }
}
