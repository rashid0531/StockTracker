import re

files_to_unpatch = [
    'lib/ui/features/dashboard/dashboard_view.dart',
    'lib/ui/features/hub/hub_view.dart',
    'lib/ui/features/import/import_view.dart',
    'lib/ui/features/profile/profile_view.dart',
]

for filepath in files_to_unpatch:
    with open(filepath, 'r') as f:
        content = f.read()
    
    # We replace the exact patterns we injected
    
    # 1. Dashboard
    content = content.replace("              return Center(\n                child: ConstrainedBox(\n                  constraints: const BoxConstraints(maxWidth: 1000),\n                  child: _buildTabContent(theme),\n                ),\n              );", "              return _buildTabContent(theme);")
    
    # 2. Hub
    content = content.replace("child: Center(\n            child: ConstrainedBox(\n              constraints: const BoxConstraints(maxWidth: 1000),\n              child: ListView(", "child: ListView(")
    content = content.replace("            ],\n          ),\n              ),\n            ),\n        ),\n      ),\n    );\n  }\n\n  String _buildActiveBreakdownString", "            ],\n          ),\n        ),\n      ),\n    );\n  }\n\n  String _buildActiveBreakdownString")

    # 3. Import
    content = content.replace("child: Center(\n            child: ConstrainedBox(\n              constraints: const BoxConstraints(maxWidth: 1000),\n              child: ListView(", "child: ListView(")
    content = content.replace("if (_currentStep == 4) _buildStep4(theme),\n            ],\n          ),\n              ),\n            ),\n        ),\n      ),\n    );\n  }\n\n  // Step Progress Indicator Pill", "if (_currentStep == 4) _buildStep4(theme),\n            ],\n          ),\n        ),\n      ),\n    );\n  }\n\n  // Step Progress Indicator Pill")
    
    # 4. Profile
    content = content.replace("return Center(\n                child: ConstrainedBox(\n                  constraints: const BoxConstraints(maxWidth: 1000),\n                  child: Padding(", "return Padding(")
    content = content.replace("Expanded(\n                    child: _buildPerformanceTab(theme),\n                  ),\n                ],\n              ),\n                  ),\n                ),\n              );\n            },\n          ),\n        ),\n      ),\n    );\n  }", "Expanded(\n                    child: _buildPerformanceTab(theme),\n                  ),\n                ],\n              );\n            },\n          ),\n        ),\n      ),\n    );\n  }")
    
    with open(filepath, 'w') as f:
        f.write(content)
