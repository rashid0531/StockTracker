import re

with open('lib/ui/features/hub/asset_creation_view.dart', 'r') as f:
    content = f.read()

bad_ui = """            Expanded(child: _buildTextField(theme, _reRoomsCtrl, "Rooms", Icons.bed_outlined, isNumber: true)),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(theme, _reWashroomsCtrl, "Washrooms", Icons.bathtub_outlined, isNumber: true)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(theme, _reGaragesCtrl, "Garages", Icons.garage_outlined, isNumber: true)),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(theme, _reSizeCtrl, "Size (sq ft)", Icons.square_foot_outlined, isNumber: true)),"""

good_ui = """            Expanded(child: TextField(
              controller: _reRoomsCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                labelText: "Rooms", labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
                filled: true, fillColor: theme.bg,
                prefixIcon: Icon(Icons.bed_outlined, color: theme.subtext, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              )
            )),
            const SizedBox(width: 14),
            Expanded(child: TextField(
              controller: _reWashroomsCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                labelText: "Washrooms", labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
                filled: true, fillColor: theme.bg,
                prefixIcon: Icon(Icons.bathtub_outlined, color: theme.subtext, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              )
            )),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: TextField(
              controller: _reGaragesCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                labelText: "Garages", labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
                filled: true, fillColor: theme.bg,
                prefixIcon: Icon(Icons.garage_outlined, color: theme.subtext, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              )
            )),
            const SizedBox(width: 14),
            Expanded(child: TextField(
              controller: _reSizeCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                labelText: "Size (sq ft)", labelStyle: TextStyle(color: theme.subtext, fontSize: 12),
                filled: true, fillColor: theme.bg,
                prefixIcon: Icon(Icons.square_foot_outlined, color: theme.subtext, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              )
            )),"""

content = content.replace(bad_ui, good_ui)

with open('lib/ui/features/hub/asset_creation_view.dart', 'w') as f:
    f.write(content)
