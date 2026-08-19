with open('lib/main.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'ui/features/onboarding/module_selection_view.dart';", "")

route_block = """      GoRoute(
        path: '/module-selection',
        builder: (context, state) => const ModuleSelectionView(),
      ),"""

content = content.replace(route_block, "")

with open('lib/main.dart', 'w') as f:
    f.write(content)
