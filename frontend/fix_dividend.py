import re

with open('lib/ui/features/dashboard/dashboard_view.dart', 'r') as f:
    content = f.read()

broken = """                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dividend Income", style: theme.titleStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text("Track projected vs actual income", style: theme.subtitleStyle),
                ],
              ),"""
fixed = """                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dividend Income", style: theme.titleStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
                      Text("Track projected vs actual income", style: theme.subtitleStyle),
                    ],
                  ),
                ],
              ),"""
content = content.replace(broken, fixed)

with open('lib/ui/features/dashboard/dashboard_view.dart', 'w') as f:
    f.write(content)
