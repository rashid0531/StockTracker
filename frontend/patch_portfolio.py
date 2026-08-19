import re

with open('lib/ui/features/dashboard/dashboard_view.dart', 'r') as f:
    content = f.read()

# Portfolio Tab
p_header_old = """              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,"""
p_header_new = """              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: theme.text),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42,
                    height: 42,"""
content = content.replace(p_header_old, p_header_new)

# Dividend Tab
d_header_old = """              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dividend Income","""
d_header_new = """              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: theme.text),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dividend Income","""
content = content.replace(d_header_old, d_header_new)
content = content.replace('                    children: [\n                      Text("Dividend Income",', '                    children: [\n                      Text("Dividend Income",') # formatting

# Wait, Dividend tab has `Column` inside `Row` `children`. If I replace `Column(` with `Row(children: [IconButton..., Column(`, then I need to add `])`
d_header_old_2 = """          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dividend Income","""
d_header_new_2 = """          // Header
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
                      Text("Dividend Income","""
# I will just write a more robust replacement for the other tabs.

with open('lib/ui/features/dashboard/dashboard_view.dart', 'w') as f:
    f.write(content)
