import re

with open('lib/ui/features/import/import_view.dart', 'r') as f:
    content = f.read()

# add import
if "import 'package:image_picker/image_picker.dart';" not in content:
    content = content.replace("import '../../core/theme.dart';", "import '../../core/theme.dart';\nimport 'package:image_picker/image_picker.dart';")

# add state variables
state_vars = """
  String _importMethod = 'METHOD_SELECT'; // METHOD_SELECT, MANUAL
  bool _isOcrLoading = false;
"""
if "_importMethod" not in content:
    content = content.replace("  int _currentStep = 1;", "  int _currentStep = 1;\n" + state_vars)

# add method for OCR picking
ocr_method = """
  Future<void> _pickAndUploadImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isEmpty) return;
    
    setState(() {
      _isOcrLoading = true;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final paths = images.map((e) => e.path).toList();
      final extracted = await apiService.uploadOcrImages(paths);
      
      setState(() {
        for (var h in extracted) {
          _stagedPositions.add({
            "ticker": h["ticker"],
            "name": h["ticker"],
            "shares": h["shares"].toDouble(),
            "price": 0.0, // OCR doesn't always reliably grab price easily in this heuristic
            "currency": _selectedPrimaryCurrency,
            "brokerage": "OCR Import",
            "date": DateTime.now().toIso8601String().substring(0, 10),
          });
        }
        _importMethod = 'MANUAL'; // switch to manual to edit the results
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Extracted ${extracted.length} positions via OCR!"),
          backgroundColor: AppColors.positive,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OCR failed: $e"),
          backgroundColor: AppColors.negative,
        ),
      );
    } finally {
      setState(() {
        _isOcrLoading = false;
      });
    }
  }
"""
if "_pickAndUploadImages" not in content:
    content = content.replace("  void _resetForNextProfile()", ocr_method + "\n  void _resetForNextProfile()")

# rename existing _buildStep3 to _buildManualEntryForm
content = content.replace("Widget _buildStep3(ThemeProvider theme) {", "Widget _buildManualEntryForm(ThemeProvider theme) {")
content = content.replace("if (_currentStep == 3) _buildStep3(theme),", "if (_currentStep == 3) _buildStep3(theme),")

# inject new _buildStep3
new_step3 = """
  Widget _buildStep3(ThemeProvider theme) {
    if (_importMethod == 'METHOD_SELECT') {
      return _buildMethodSelector(theme);
    }
    return _buildManualEntryForm(theme);
  }

  Widget _buildMethodSelector(ThemeProvider theme) {
    if (_isOcrLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.border, width: 1.5),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(color: AppColors.positive),
            SizedBox(height: 20),
            Text("Analyzing Portfolio Images via AI...", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Stitching images and extracting tickers/quantities.", textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Select Import Method", style: theme.cardTitleStyle.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        
        _buildMethodCard(
          theme: theme,
          title: "Upload Portfolio Images (AI OCR)",
          subtitle: "Take screenshots of your brokerage account. We use AI to extract tickers and shares automatically.",
          icon: Icons.document_scanner,
          onTap: _pickAndUploadImages,
          badge: "BETA",
          badgeColor: Colors.blue,
        ),
        const SizedBox(height: 16),
        
        _buildMethodCard(
          theme: theme,
          title: "Connect Broker (API)",
          subtitle: "Securely link your financial institution for automatic syncing.",
          icon: Icons.account_balance,
          onTap: () {}, // placeholder
          badge: "COMING SOON",
          badgeColor: Colors.orange,
        ),
        const SizedBox(height: 16),
        
        _buildMethodCard(
          theme: theme,
          title: "Manual Entry",
          subtitle: "Type in your stock tickers and quantities manually.",
          icon: Icons.keyboard,
          onTap: () => setState(() => _importMethod = 'MANUAL'),
          badge: null,
          badgeColor: null,
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required ThemeProvider theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.positive.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.positive, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: theme.cardTitleStyle.copyWith(fontSize: 15)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor!.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.subtitleStyle.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.subtext),
          ],
        ),
      ),
    );
  }
"""

if "Widget _buildMethodSelector(ThemeProvider theme)" not in content:
    content = content.replace("  Widget _buildManualEntryForm(ThemeProvider theme) {", new_step3 + "\n  Widget _buildManualEntryForm(ThemeProvider theme) {")

with open('lib/ui/features/import/import_view.dart', 'w') as f:
    f.write(content)
