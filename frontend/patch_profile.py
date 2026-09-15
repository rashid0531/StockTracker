import re

with open('lib/ui/features/profile/profile_view.dart', 'r') as f:
    content = f.read()

bad_body = """              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Header Row with back and home buttons"""

good_body = """              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // Header Row with back and home buttons"""

content = content.replace(bad_body, good_body)

bad_end = """                        ),
                      ],
                    ),
                  ),
                ],
              ),
              );
            },
          ),
        ),
      ),
    );
  }
}
"""

good_end = """                        ),
                      ],
                    ),
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
  }
}
"""

content = content.replace(bad_end, good_end)

with open('lib/ui/features/profile/profile_view.dart', 'w') as f:
    f.write(content)
