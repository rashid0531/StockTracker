import re

with open('../wealth_tracker/app/routers/real_estate.py', 'r') as f:
    content = f.read()

# Add is_primary_residence and projection logic to create
if 'is_primary_residence' not in content:
    content = content.replace(
        'from app.models import RealEstateAsset',
        'from app.models import RealEstateAsset, RealEstateProjection\nfrom datetime import datetime\n'
    )
    content = content.replace(
        'from app.schemas import (',
        'from app.schemas import (\n    RealEstateProjectionResponse,'
    )
    
    create_body = """    asset = RealEstateAsset(
        user_id=req.user_id,
        property_name=req.property_name,
        property_type=req.property_type,
        region=req.region or "North America (NA)",
        property_category=req.property_category or "Single-Family",
        structural_type=req.structural_type or req.property_type,
        tenure_model=req.tenure_model or "Freehold",
        purchase_price=req.purchase_price,
        current_value=req.current_value,
        mortgage_balance=req.mortgage_balance,
        monthly_rent_income=req.monthly_rent_income,
        monthly_expenses=req.monthly_expenses,
        address=req.address,
        purchase_date=req.purchase_date or date.today(),
        is_primary_residence=req.is_primary_residence,
    )
    db.add(asset)
    await db.commit()
    await db.refresh(asset)
    
    # Generate 35-year mock projection
    current_year = datetime.now().year
    proj_val = float(asset.current_value)
    projections = []
    for i in range(36):
        proj = RealEstateProjection(
            real_estate_id=asset.id,
            projection_year=current_year + i,
            projected_value=Decimal(str(proj_val))
        )
        projections.append(proj)
        proj_val *= 1.035
        
    db.add_all(projections)
    await db.commit()
    
    return asset"""
    
    # Replace the body of create_real_estate_asset
    content = re.sub(
        r'    asset = RealEstateAsset\(.*?return asset',
        create_body,
        content,
        flags=re.DOTALL
    )

# Add GET projection endpoint
if 'def get_real_estate_projection' not in content:
    content += """

@router.get("/{property_id}/projection", response_model=List[RealEstateProjectionResponse])
async def get_real_estate_projection(
    property_id: UUID, db: AsyncSession = Depends(get_db)
):
    stmt = select(RealEstateProjection).where(RealEstateProjection.real_estate_id == property_id).order_by(RealEstateProjection.projection_year)
    result = await db.execute(stmt)
    projections = result.scalars().all()
    
    if not projections:
        # Fallback or error
        return []
        
    return [RealEstateProjectionResponse(year=p.projection_year, projected_value=p.projected_value) for p in projections]
"""

with open('../wealth_tracker/app/routers/real_estate.py', 'w') as f:
    f.write(content)
