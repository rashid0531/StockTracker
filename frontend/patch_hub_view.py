import re

with open('lib/ui/features/hub/hub_view.dart', 'r') as f:
    content = f.read()

bad_body = """      body: theme.buildBackground(
        child: SafeArea(
          child: ListView("""

good_body = """      body: theme.buildBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView("""

content = content.replace(bad_body, good_body)

# Don't forget to close the Center and ConstrainedBox!
bad_end = """                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildActiveBreakdownString(PillarPreferencesProvider prefs) {"""

good_end = """                ),
            ],
          ),
              ),
            ),
        ),
      ),
    );
  }

  String _buildActiveBreakdownString(PillarPreferencesProvider prefs) {"""

content = content.replace(bad_end, good_end)

with open('lib/ui/features/hub/hub_view.dart', 'w') as f:
    f.write(content)
