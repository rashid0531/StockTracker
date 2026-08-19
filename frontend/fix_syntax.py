import re

with open('lib/ui/features/dashboard/dashboard_view.dart', 'r') as f:
    content = f.read()

# Fix Calendar Tab syntax
cal_broken = """                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dividend Calendar", style: theme.titleStyle),
                    Text("Chronological schedule of ex-dividend dates and payments.", style: theme.subtitleStyle),
                  ],
                ),
              ),"""
cal_fixed = """                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dividend Calendar", style: theme.titleStyle),
                        Text("Chronological schedule of ex-dividend dates and payments.", style: theme.subtitleStyle),
                      ],
                    ),
                  ],
                ),
              ),"""
content = content.replace(cal_broken, cal_fixed)

# Now apply History tab
hist_old = """      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Transactions Ledger","""
hist_new = """      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu, color: theme.text),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Transactions Ledger","""
content = content.replace(hist_old, hist_new)

# Wait, if I replace `Column(` with `Row( children: [ IconButton..., Column(`, I need to add `])` to close the new Row!
hist_broken_closing = """                    Text("Transactions Ledger", style: theme.titleStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
                    Text("Comprehensive history of buys, sells, and dividends.", style: theme.subtitleStyle),
                  ],
                ),
              ],
            ),
            IconButton("""
hist_fixed_closing = """                    Text("Transactions Ledger", style: theme.titleStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w900)),
                    Text("Comprehensive history of buys, sells, and dividends.", style: theme.subtitleStyle),
                  ],
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton("""
# Actually, I should just use regex or be very careful.

with open('lib/ui/features/dashboard/dashboard_view.dart', 'w') as f:
    f.write(content)
