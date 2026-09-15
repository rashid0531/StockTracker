import re

with open('lib/ui/features/import/import_view.dart', 'r') as f:
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

bad_end = """              // STEP 4: Success & Multi-Profile Prompt
              if (_currentStep == 4) _buildStep4(theme),
            ],
          ),
        ),
      ),
    );
  }

  // Step Progress Indicator Pill"""

good_end = """              // STEP 4: Success & Multi-Profile Prompt
              if (_currentStep == 4) _buildStep4(theme),
            ],
          ),
              ),
            ),
        ),
      ),
    );
  }

  // Step Progress Indicator Pill"""

content = content.replace(bad_end, good_end)

with open('lib/ui/features/import/import_view.dart', 'w') as f:
    f.write(content)
