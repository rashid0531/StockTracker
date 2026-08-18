import re

with open('../wealth_tracker/app/schemas.py', 'r') as f:
    content = f.read()

# Add is_primary_residence to RealEstateCreateRequest
if 'is_primary_residence: bool =' not in content:
    content = content.replace(
        '    purchase_date: Optional[date] = None',
        '    purchase_date: Optional[date] = None\n    is_primary_residence: bool = True'
    )

# Add is_primary_residence to RealEstateResponse
if 'is_primary_residence: bool\n' not in content:
    content = content.replace(
        '    purchase_date: Optional[date]\n    created_at: datetime',
        '    purchase_date: Optional[date]\n    is_primary_residence: bool\n    created_at: datetime'
    )

# Add RealEstateProjectionResponse
if 'class RealEstateProjectionResponse' not in content:
    content += """

class RealEstateProjectionResponse(BaseModel):
    year: int
    projected_value: Decimal

    model_config = ConfigDict(from_attributes=True)
"""

with open('../wealth_tracker/app/schemas.py', 'w') as f:
    f.write(content)
