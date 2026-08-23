import re

with open('lib/ui/features/dashboard/dashboard_view.dart', 'r') as f:
    content = f.read()

# 1. Remove the "AI Suggestion" button from the header of _buildDividendTab
header_pattern = r"""              Row\(
                children: \[
                  InkWell\(
                    onTap: \(\) => context\.push\('/dividend-suggestion'\),
                    borderRadius: BorderRadius\.circular\(12\),
                    child: Container\(
                      padding: const EdgeInsets\.symmetric\(horizontal: 12, vertical: 8\),
                      decoration: BoxDecoration\(
                        color: AppColors\.positive\.withOpacity\(0\.1\),
                        borderRadius: BorderRadius\.circular\(20\),
                        border: Border\.all\(color: AppColors\.positive\),
                      \),
                      child: Text\("AI Suggestion", style: TextStyle\(color: AppColors\.positive, fontWeight: FontWeight\.bold, fontSize: 12\)\),
                    \),
                  \),
                  const SizedBox\(width: 12\),"""

content = re.sub(header_pattern, "", content)

# 2. Add back button to the DividendTab header
dividend_header = r"""                  IconButton\(
                    icon: Icon\(Icons\.menu, color: theme\.text\),
                    onPressed: \(\) => _scaffoldKey\.currentState\?\.openDrawer\(\),
                  \),"""
dividend_header_new = """                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.text),
                    onPressed: () => setState(() => _currentTabIndex = 0),
                  ),
                  IconButton(
                    icon: Icon(Icons.menu, color: theme.text),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),"""
if "setState(() => _currentTabIndex = 0)" not in content.split("_buildDividendTab")[1].split("InkWell")[0]:
    content = content.replace(dividend_header, dividend_header_new, 1)

# 3. Add back buttons to FIRE, Calendar, Settings tabs.
def add_back_button(tab_name):
    global content
    idx = content.find(tab_name)
    if idx == -1: return
    
    # Find the menu button
    menu_btn = """                  IconButton(
                    icon: Icon(Icons.menu, color: theme.text),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),"""
    menu_btn_indented1 = """            IconButton(
              icon: Icon(Icons.menu, color: theme.text),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),"""
    menu_btn_indented2 = """                    IconButton(
                      icon: Icon(Icons.menu, color: theme.text),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),"""
    
    new_btn1 = """            IconButton(
              icon: Icon(Icons.arrow_back, color: theme.text),
              onPressed: () => setState(() => _currentTabIndex = 0),
            ),
            IconButton(
              icon: Icon(Icons.menu, color: theme.text),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),"""
    new_btn2 = """                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.text),
                      onPressed: () => setState(() => _currentTabIndex = 0),
                    ),
                    IconButton(
                      icon: Icon(Icons.menu, color: theme.text),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),"""

    # Look for the first occurrence of menu button after the tab definition
    sub_content = content[idx:]
    
    if tab_name == "_buildFireTab":
        content = content[:idx] + sub_content.replace(menu_btn_indented1, new_btn1, 1)
    elif tab_name == "_buildCalendarTab":
        content = content[:idx] + sub_content.replace(menu_btn_indented2, new_btn2, 1)

add_back_button("_buildFireTab")
add_back_button("_buildCalendarTab")

# 4. Settings tab doesn't have a menu button, so we need to add the whole Row manually.
settings_header = """        Text("Settings", style: theme.titleStyle),"""
settings_header_new = """        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: theme.text),
              onPressed: () => setState(() => _currentTabIndex = 0),
            ),
            IconButton(
              icon: Icon(Icons.menu, color: theme.text),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 8),
            Text("Settings", style: theme.titleStyle),
          ]
        ),"""
if "setState(() => _currentTabIndex = 0)" not in content.split("_buildSettingsTab")[1].split("Text(\"Manage")[0]:
    content = content.replace(settings_header, settings_header_new)

# 5. Move the AI suggestion button into the Dividend Action Buttons row
action_buttons = """          // Dividend Action Buttons
          Row(
            children: [
              Expanded(
                child: HoverButton(
                  label: "Analytics",
                  icon: Icons.pie_chart,
                  onTap: () => context.push('/dividend-analytics?id=${_viewModel.dividendProfileId}'),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HoverButton(
                  label: "Objective",
                  icon: Icons.local_fire_department,
                  onTap: () => setState(() => _currentTabIndex = 2),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HoverButton(
                  label: "Calendar",
                  icon: Icons.calendar_month,
                  onTap: () => setState(() => _currentTabIndex = 3),
                  theme: theme,
                ),
              ),
            ],
          ),"""

action_buttons_new = """          // Dividend Action Buttons
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: HoverButton(
                      label: "Analytics",
                      icon: Icons.pie_chart,
                      onTap: () => context.push('/dividend-analytics?id=${_viewModel.dividendProfileId}'),
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HoverButton(
                      label: "Objective",
                      icon: Icons.local_fire_department,
                      onTap: () => setState(() => _currentTabIndex = 2),
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: HoverButton(
                      label: "Calendar",
                      icon: Icons.calendar_month,
                      onTap: () => setState(() => _currentTabIndex = 3),
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HoverButton(
                      label: "Suggestion",
                      icon: Icons.auto_awesome,
                      onTap: () => context.push('/dividend-suggestion'),
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ],
          ),"""

content = content.replace(action_buttons, action_buttons_new)

with open('lib/ui/features/dashboard/dashboard_view.dart', 'w') as f:
    f.write(content)

