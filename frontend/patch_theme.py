import re

with open('lib/ui/core/theme.dart', 'r') as f:
    content = f.read()

bad_body = """          // 5. Content overlay
          Positioned.fill(
            child: widget.child,
          ),"""

good_body = """          // 5. Content overlay
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: widget.child,
              ),
            ),
          ),"""

content = content.replace(bad_body, good_body)

with open('lib/ui/core/theme.dart', 'w') as f:
    f.write(content)
