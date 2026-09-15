import re

with open('lib/ui/features/profile/profile_view.dart', 'r') as f:
    content = f.read()

bad_body = """                  Expanded(
                    child: _buildPerformanceTab(theme),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}"""

good_body = """                  Expanded(
                    child: _buildPerformanceTab(theme),
                  ),
                ],
              ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }"""

content = content.replace(bad_body, good_body)

with open('lib/ui/features/profile/profile_view.dart', 'w') as f:
    f.write(content)
