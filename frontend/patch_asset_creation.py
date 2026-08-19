import re

with open('lib/ui/features/hub/asset_creation_view.dart', 'r') as f:
    content = f.read()

# Add controllers
content = content.replace(
    '  final _reAddrCtrl = TextEditingController();',
    '  final _reAddrCtrl = TextEditingController();\n  final _reRoomsCtrl = TextEditingController();\n  final _reWashroomsCtrl = TextEditingController();\n  final _reGaragesCtrl = TextEditingController();\n  final _reSizeCtrl = TextEditingController();'
)

# Add to dispose
if '_reRoomsCtrl.dispose()' not in content:
    content = content.replace(
        '    _reAddrCtrl.dispose();',
        '    _reAddrCtrl.dispose();\n    _reRoomsCtrl.dispose();\n    _reWashroomsCtrl.dispose();\n    _reGaragesCtrl.dispose();\n    _reSizeCtrl.dispose();'
    )

# Add UI fields
ui_fields = """
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(theme, _reRoomsCtrl, "Rooms", Icons.bed_outlined, isNumber: true)),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(theme, _reWashroomsCtrl, "Washrooms", Icons.bathtub_outlined, isNumber: true)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(theme, _reGaragesCtrl, "Garages", Icons.garage_outlined, isNumber: true)),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(theme, _reSizeCtrl, "Size (sq ft)", Icons.square_foot_outlined, isNumber: true)),
          ],
        ),
"""

# Insert UI fields right before the Primary Residence switch
content = content.replace(
    '        const SizedBox(height: 14),\n        Material(\n          color: Colors.transparent,\n          child: SwitchListTile(',
    ui_fields + '        const SizedBox(height: 14),\n        Material(\n          color: Colors.transparent,\n          child: SwitchListTile('
)

# Also handle if it's slightly differently formatted:
# Wait, I'll use regex if needed, but string replacement is safer if exact.

# Add to _handleSubmit
content = content.replace(
    '          "is_primary_residence": _isPrimaryResidence,',
    '          "is_primary_residence": _isPrimaryResidence,\n          "rooms": int.tryParse(_reRoomsCtrl.text) ?? 0,\n          "washrooms": int.tryParse(_reWashroomsCtrl.text) ?? 0,\n          "garages": int.tryParse(_reGaragesCtrl.text) ?? 0,\n          "size_sqft": int.tryParse(_reSizeCtrl.text) ?? 0,'
)

with open('lib/ui/features/hub/asset_creation_view.dart', 'w') as f:
    f.write(content)
