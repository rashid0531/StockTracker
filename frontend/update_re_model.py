with open('lib/data/models/real_estate.dart', 'r') as f:
    content = f.read()

# Add fields
content = content.replace(
    '  final bool isPrimaryResidence;',
    '  final bool isPrimaryResidence;\n  final int rooms;\n  final int washrooms;\n  final int garages;\n  final int sizeSqft;'
)

# Add to constructor
content = content.replace(
    '    this.isPrimaryResidence = true,\n  });',
    '    this.isPrimaryResidence = true,\n    this.rooms = 0,\n    this.washrooms = 0,\n    this.garages = 0,\n    this.sizeSqft = 0,\n  });'
)

# Add to fromJson
content = content.replace(
    "      isPrimaryResidence: json['is_primary_residence'] as bool? ?? true,",
    "      isPrimaryResidence: json['is_primary_residence'] as bool? ?? true,\n      rooms: json['rooms'] as int? ?? 0,\n      washrooms: json['washrooms'] as int? ?? 0,\n      garages: json['garages'] as int? ?? 0,\n      sizeSqft: json['size_sqft'] as int? ?? 0,"
)

# Add to toJson
content = content.replace(
    "      'is_primary_residence': isPrimaryResidence,",
    "      'is_primary_residence': isPrimaryResidence,\n      'rooms': rooms,\n      'washrooms': washrooms,\n      'garages': garages,\n      'size_sqft': sizeSqft,"
)

with open('lib/data/models/real_estate.dart', 'w') as f:
    f.write(content)
