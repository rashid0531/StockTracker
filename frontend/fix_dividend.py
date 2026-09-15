import re

with open('lib/ui/features/dividend/dividend_suggestion_view.dart', 'r') as f:
    content = f.read()

bad_body = """            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMeterCard({"""

good_body = """            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMeterCard({"""

content = content.replace(bad_body, good_body)

# And remove the extra closing brackets I accidentally added to the end of the file
content = re.sub(r'        \),\n          \),\n        \),\n      \),\n    \);\n  }\n}\n$', r'}\n', content)

with open('lib/ui/features/dividend/dividend_suggestion_view.dart', 'w') as f:
    f.write(content)
