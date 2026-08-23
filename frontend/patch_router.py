import re

with open('lib/main.dart', 'r') as f:
    content = f.read()

import_statement = "import 'ui/features/dividend/dividend_suggestion_view.dart';\n"
if "dividend_suggestion_view.dart" not in content:
    content = content.replace("import 'ui/features/dashboard/dashboard_view.dart';", "import 'ui/features/dashboard/dashboard_view.dart';\n" + import_statement)

route_code = """
      GoRoute(
        path: '/dividend-suggestion',
        builder: (context, state) => const DividendSuggestionView(),
      ),
"""
if "/dividend-suggestion" not in content:
    content = content.replace("routes: [", "routes: [" + route_code)

with open('lib/main.dart', 'w') as f:
    f.write(content)
