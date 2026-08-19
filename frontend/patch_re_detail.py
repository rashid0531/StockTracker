with open('lib/ui/features/real_estate/real_estate_detail_view.dart', 'r') as f:
    content = f.read()

features_block = """
            const SizedBox(height: 24),
            
            // Property Features
            Text("Property Features", style: theme.cardTitleStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricItem("Rooms", _asset!.rooms.toString(), theme),
                  _buildMetricItem("Washrooms", _asset!.washrooms.toString(), theme),
                  _buildMetricItem("Garages", _asset!.garages.toString(), theme),
                  _buildMetricItem("Size (sq ft)", _asset!.sizeSqft.toString(), theme),
                ],
              ),
            ),
"""

content = content.replace(
    '            const SizedBox(height: 24),\n            \n            // Graph Section',
    features_block + '\n            const SizedBox(height: 24),\n            \n            // Graph Section'
)

with open('lib/ui/features/real_estate/real_estate_detail_view.dart', 'w') as f:
    f.write(content)
