from datetime import date
from decimal import Decimal
from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import RealEstateAsset, RealEstateProjection
from datetime import datetime

from app.schemas import (
    RealEstateProjectionResponse,
    RealEstateCreateRequest,
    RealEstateResponse,
    UserRealEstateResponse,
)

router = APIRouter(prefix="/real-estate", tags=["Real Estate"])


@router.get("/{user_id}", response_model=UserRealEstateResponse)
async def get_user_real_estate(
    user_id: UUID, db: AsyncSession = Depends(get_db)
):
    stmt = select(RealEstateAsset).where(RealEstateAsset.user_id == user_id)
    result = await db.execute(stmt)
    properties = list(result.scalars().all())

    total_val = sum((p.current_value for p in properties), Decimal("0.0"))
    total_mort = sum((p.mortgage_balance for p in properties), Decimal("0.0"))
    total_equity = total_val - total_mort
    total_cashflow = sum(
        ((p.monthly_rent_income - p.monthly_expenses) for p in properties),
        Decimal("0.0"),
    )

    return UserRealEstateResponse(
        user_id=user_id,
        total_value=total_val,
        total_mortgage=total_mort,
        total_net_equity=total_equity,
        total_monthly_cashflow=total_cashflow,
        properties=properties,
    )


@router.post("", response_model=RealEstateResponse, status_code=status.HTTP_201_CREATED)
async def create_real_estate_asset(
    req: RealEstateCreateRequest, db: AsyncSession = Depends(get_db)
):
    asset = RealEstateAsset(
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
        rooms=req.rooms,
        washrooms=req.washrooms,
        garages=req.garages,
        size_sqft=req.size_sqft,
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
    
    return asset


@router.delete("/{asset_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_real_estate_asset(
    asset_id: UUID, db: AsyncSession = Depends(get_db)
):
    stmt = select(RealEstateAsset).where(RealEstateAsset.id == asset_id)
    res = await db.execute(stmt)
    asset = res.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=404, detail="Real Estate asset not found")
    await db.delete(asset)
    await db.commit()
    return None


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
