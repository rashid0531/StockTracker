import re

with open('lib/ui/features/dashboard/dashboard_view.dart', 'r') as f:
    content = f.read()

# Add GlobalKey
if '_scaffoldKey' not in content:
    content = content.replace(
        '  late final DashboardViewModel _viewModel',
        '  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();\n  late final DashboardViewModel _viewModel'
    )

# Add scaffold key and drawer, remove isWide bottom bar check
# Original Scaffold:
#    return Scaffold(
#      backgroundColor: theme.bg,
scaffold_start = '''    return Scaffold(
      backgroundColor: theme.bg,
      body: theme.buildBackground('''
new_scaffold_start = '''    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.bg,
      drawer: Drawer(
        backgroundColor: theme.bg,
        child: _buildWebSidePanel(theme),
      ),
      body: theme.buildBackground('''
content = content.replace(scaffold_start, new_scaffold_start)

# Remove row from AnimatedBuilder
animated_builder_old = '''              if (isWide) {
                return Row(
                  children: [
                    _buildWebSidePanel(theme),
                    Expanded(
                      child: _buildTabContent(theme),
                    ),
                  ],
                );
              }

              return _buildTabContent(theme);'''
animated_builder_new = '''              return _buildTabContent(theme);'''
content = content.replace(animated_builder_old, animated_builder_new)

# Remove BottomNavigationBar
bottom_nav = '''      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _currentTabIndex,
              onTap: (index) {
                setState(() {
                  _currentTabIndex = index;
                });
                if (index == 1) {
                  _viewModel.loadDividendTab();
                } else if (index == 3) {
                  _viewModel.loadCalendar();
                } else if (index == 4) {
                  _viewModel.loadTransactions();
                }
              },
              backgroundColor: theme.card,
              selectedItemColor: AppColors.positive,
              unselectedItemColor: theme.subtext,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              unselectedLabelStyle: const TextStyle(fontSize: 9),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Text("📊", style: TextStyle(fontSize: 18)),
                  activeIcon: Text("📊", style: TextStyle(fontSize: 18)),
                  label: "Portfolio",
                ),
                BottomNavigationBarItem(
                  icon: Text("💰", style: TextStyle(fontSize: 18)),
                  activeIcon: Text("💰", style: TextStyle(fontSize: 18)),
                  label: "Dividend",
                ),
                BottomNavigationBarItem(
                  icon: Text("📜", style: TextStyle(fontSize: 18)),
                  activeIcon: Text("📜", style: TextStyle(fontSize: 18)),
                  label: "History",
                ),
                BottomNavigationBarItem(
                  icon: Text("⚙️", style: TextStyle(fontSize: 18)),
                  activeIcon: Text("⚙️", style: TextStyle(fontSize: 18)),
                  label: "Settings",
                ),
              ],
            ),'''
content = content.replace(bottom_nav, '')

with open('lib/ui/features/dashboard/dashboard_view.dart', 'w') as f:
    f.write(content)
