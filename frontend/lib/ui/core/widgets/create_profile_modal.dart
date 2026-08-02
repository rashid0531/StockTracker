import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../theme.dart';

class CreatePillarProfileModal extends StatefulWidget {
  final VoidCallback onProfileCreated;

  const CreatePillarProfileModal({
    super.key,
    required this.onProfileCreated,
  });

  static void show(BuildContext context, {required VoidCallback onProfileCreated}) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => CreatePillarProfileModal(onProfileCreated: onProfileCreated),
    );
  }

  @override
  State<CreatePillarProfileModal> createState() => _CreatePillarProfileModalState();
}

class _CreatePillarProfileModalState extends State<CreatePillarProfileModal> {
  final ApiService _apiService = ApiService();
  final _nameCtrl = TextEditingController();

  String _selectedPillar = "Stocks";
  String _selectedType = "TFSA";
  String _selectedCountry = "Canada";
  bool _isSubmitting = false;

  final Map<String, List<String>> _pillarAccountTypes = {
    "Stocks": ["TFSA", "RRSP", "401(k)", "Taxable Brokerage", "Crypto Vault"],
    "Real-Estate": ["Primary Residence", "Rental Property", "Commercial Real Estate", "REIT / Land"],
    "Precious Metals": ["Gold Vault", "Silver Reserve", "Platinum Vault", "Bullion Storage"],
    "Health": ["Vital Metrics Log", "Fitness Tracker", "Sleep Recovery", "Comprehensive Health Index"],
  };

  final Map<String, Map<String, dynamic>> _pillarMeta = {
    "Stocks": {"icon": "📈", "color": AppColors.positive, "label": "Stocks & Equities"},
    "Real-Estate": {"icon": "🏠", "color": const Color(0xFF3B82F6), "label": "Real-Estate"},
    "Precious Metals": {"icon": "🥇", "color": const Color(0xFFF59E0B), "label": "Precious Metals"},
    "Health": {"icon": "❤️", "color": const Color(0xFFEC4899), "label": "Health & Wellness"},
  };

  void _onPillarSelected(String pillar) {
    setState(() {
      _selectedPillar = pillar;
      _selectedType = _pillarAccountTypes[pillar]!.first;
    });
  }

  Future<void> _handleCreate() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      await _apiService.createProfile(
        name: _nameCtrl.text.trim(),
        country: _selectedCountry,
        type: _selectedType,
        pillarCategory: _selectedPillar,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onProfileCreated();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Create Pillar Profile ✨", style: theme.cardTitleStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
              IconButton(
                icon: Icon(Icons.close_rounded, color: theme.subtext),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text("Select Pillar Category", style: theme.subtitleStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 10),

          // 4-Pillar Grid Selection Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemCount: _pillarMeta.keys.length,
            itemBuilder: (context, index) {
              final key = _pillarMeta.keys.elementAt(index);
              final meta = _pillarMeta[key]!;
              final bool isSelected = _selectedPillar == key;
              final Color color = meta["color"] as Color;

              return InkWell(
                onTap: () => _onPillarSelected(key),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : theme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : theme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(meta["icon"] as String, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          meta["label"] as String,
                          style: theme.bodyStyle.copyWith(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? color : theme.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Profile Name
          TextField(
            controller: _nameCtrl,
            style: TextStyle(color: theme.text),
            decoration: InputDecoration(
              labelText: "Profile Name (e.g., TFSA Growth, Beach Condo, Gold Vault)",
              labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
              filled: true,
              fillColor: theme.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // Dynamic Account / Asset Type Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Account / Asset Type", style: theme.subtitleStyle.copyWith(fontSize: 11)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          dropdownColor: theme.card,
                          style: TextStyle(color: theme.text, fontSize: 13),
                          items: _pillarAccountTypes[_selectedPillar]!.map((t) {
                            return DropdownMenuItem(value: t, child: Text(t));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedType = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Country Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Jurisdiction", style: theme.subtitleStyle.copyWith(fontSize: 11)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountry,
                          isExpanded: true,
                          dropdownColor: theme.card,
                          style: TextStyle(color: theme.text, fontSize: 13),
                          items: ["Canada", "United States", "United Kingdom", "Global"].map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCountry = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _pillarMeta[_selectedPillar]!["color"] as Color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isSubmitting ? null : _handleCreate,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Create Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
