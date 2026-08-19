import re

# 1. Update models.py
with open('../wealth_tracker/app/models.py', 'r') as f:
    content = f.read()

if 'rooms: Mapped[int]' not in content:
    content = content.replace(
        '    is_primary_residence: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)',
        '    is_primary_residence: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)\n    rooms: Mapped[int] = mapped_column(Integer, default=0, nullable=False)\n    washrooms: Mapped[int] = mapped_column(Integer, default=0, nullable=False)\n    garages: Mapped[int] = mapped_column(Integer, default=0, nullable=False)\n    size_sqft: Mapped[int] = mapped_column(Integer, default=0, nullable=False)'
    )

with open('../wealth_tracker/app/models.py', 'w') as f:
    f.write(content)

# 2. Update schemas.py
with open('../wealth_tracker/app/schemas.py', 'r') as f:
    content = f.read()

if 'rooms: int = 0' not in content:
    content = content.replace(
        '    is_primary_residence: bool = True\n',
        '    is_primary_residence: bool = True\n    rooms: int = 0\n    washrooms: int = 0\n    garages: int = 0\n    size_sqft: int = 0\n'
    )
    # Also for response
    content = content.replace(
        '    is_primary_residence: bool\n',
        '    is_primary_residence: bool\n    rooms: int\n    washrooms: int\n    garages: int\n    size_sqft: int\n'
    )

with open('../wealth_tracker/app/schemas.py', 'w') as f:
    f.write(content)

# 3. Update router
with open('../wealth_tracker/app/routers/real_estate.py', 'r') as f:
    content = f.read()

if 'rooms=req.rooms' not in content:
    content = content.replace(
        '        is_primary_residence=req.is_primary_residence,',
        '        is_primary_residence=req.is_primary_residence,\n        rooms=req.rooms,\n        washrooms=req.washrooms,\n        garages=req.garages,\n        size_sqft=req.size_sqft,'
    )

with open('../wealth_tracker/app/routers/real_estate.py', 'w') as f:
    f.write(content)

