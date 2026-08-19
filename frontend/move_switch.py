import re

with open('lib/ui/features/hub/asset_creation_view.dart', 'r') as f:
    content = f.read()

switch_code = """        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            title: Text("Primary Residence", style: TextStyle(color: theme.text, fontSize: 14)),
            subtitle: Text("Turn off if this is an Investment Property", style: TextStyle(color: theme.subtext, fontSize: 12)),
            value: _isPrimaryResidence,
            activeTrackColor: AppColors.positive.withValues(alpha: 0.5),
            activeThumbColor: AppColors.positive,
            contentPadding: EdgeInsets.zero,
            onChanged: (bool value) {
              setState(() {
                _isPrimaryResidence = value;
              });
            },
          ),
        ),"""

# Remove the existing switch
content = content.replace(switch_code, "")

# Insert it before the Property Name text field (or after the section title)
section_title = '        Text("5. Financial Valuation & Details", style: theme.cardTitleStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),\n        const SizedBox(height: 10),'

new_section_start = section_title + switch_code + '\n        const SizedBox(height: 14),'

content = content.replace(section_title, new_section_start)

# Change the label text of _reRentCtrl
content = content.replace('labelText: "Monthly Rent (\$)",', 'labelText: _isPrimaryResidence ? "Mortgage amount / Monthly rent" : "Monthly Rent (\$)",')

with open('lib/ui/features/hub/asset_creation_view.dart', 'w') as f:
    f.write(content)
