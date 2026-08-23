import re

with open('lib/ui/features/dashboard/dashboard_view.dart', 'r') as f:
    content = f.read()

# Fix the mismatched closing braces in the dividend header
bad_header = """                  InkWell(
                    onTap: () {
                      _viewModel.loadDividendTab();
                      _viewModel.loadReceivedDividends();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.border),
                      ),
                      child: Text("🔄", style: TextStyle(color: theme.text, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),"""

good_header = """                  InkWell(
                    onTap: () {
                      _viewModel.loadDividendTab();
                      _viewModel.loadReceivedDividends();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.border),
                      ),
                      child: Text("🔄", style: TextStyle(color: theme.text, fontSize: 16)),
                    ),
                  ),
            ],
          ),"""

content = content.replace(bad_header, good_header)

with open('lib/ui/features/dashboard/dashboard_view.dart', 'w') as f:
    f.write(content)
