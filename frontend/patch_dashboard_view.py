import re

with open('lib/ui/features/dashboard/dashboard_view.dart', 'r') as f:
    content = f.read()

bad_body = """              return _buildTabContent(theme);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWebSidePanel(ThemeProvider theme) {"""

good_body = """              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: _buildTabContent(theme),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWebSidePanel(ThemeProvider theme) {"""

content = content.replace(bad_body, good_body)

with open('lib/ui/features/dashboard/dashboard_view.dart', 'w') as f:
    f.write(content)
