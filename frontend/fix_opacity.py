import re

with open('lib/ui/features/dividend/dividend_suggestion_view.dart', 'r') as f:
    content = f.read()

content = content.replace("withOpacity(0.1)", "withValues(alpha: 0.1)")
content = content.replace("withOpacity(0.05)", "withValues(alpha: 0.05)")
content = content.replace("withOpacity(0.8)", "withValues(alpha: 0.8)")

with open('lib/ui/features/dividend/dividend_suggestion_view.dart', 'w') as f:
    f.write(content)
