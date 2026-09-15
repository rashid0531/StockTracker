import re

with open('lib/ui/features/dividend/dividend_suggestion_view.dart', 'r') as f:
    content = f.read()

bad_body = """      body: SingleChildScrollView("""

good_body = """      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView("""

content = content.replace(bad_body, good_body)

bad_end = """        ),
      ),
    );
  }
}
"""

good_end = """        ),
          ),
        ),
      ),
    );
  }
}
"""

content = content.replace(bad_end, good_end)

with open('lib/ui/features/dividend/dividend_suggestion_view.dart', 'w') as f:
    f.write(content)
