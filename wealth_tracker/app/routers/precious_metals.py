from datetime import date
from decimal import Decimal
from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import PreciousMetalAsset
from app.schemas import (
    PreciousMetalCreateRequest,
    PreciousMetalResponse,
    UserPreciousMetalsResponse,
)

router = APIRouter(prefix="/precious-metals", tags=["Precious Metals"])


@router.get("/{user_id}", response_model=UserPreciousMetalsResponse)
async def get_user_precious_metals(
    user_id: UUID, db: AsyncSession = Depends(get_db)
):
    stmt = select(PreciousMetalAsset).where(PreciousMetalAsset.user_id == user_id)
    result = await db.execute(stmt)
    metals = list(result.scalars().all())

    total_val = sum(
        (m.weight_oz * m.current_spot_price_per_oz for m in metals),
        Decimal("0.0"),
    )
    total_wt = sum((m.weight_oz for m in metals), Decimal("0.0"))
    total_cost = sum(
        (m.weight_oz * m.purchase_price_per_oz for m in metals),
        Decimal("0.0"),
    )
    total_gain = total_val - total_cost

    return UserPreciousMetalsResponse(
        user_id=user_id,
        total_value=total_val,
        total_weight_oz=total_wt,
        total_gain_loss=total_gain,
        metals=metals,
    )


@router.post("", response_model=PreciousMetalResponse, status_code=status.HTTP_201_CREATED)
async def create_precious_metal_asset(
    req: PreciousMetalCreateRequest, db: AsyncSession = Depends(get_db)
):
    asset = PreciousMetalAsset(
        user_id=req.user_id,
        metal_type=req.metal_type,
        form=req.form,
        weight_oz=req.weight_oz,
        purity_percent=req.purity_percent,
        purchase_price_per_oz=req.purchase_price_per_oz,
        current_spot_price_per_oz=req.current_spot_price_per_oz,
        storage_location=req.storage_location or "Home Safe",
        purchase_date=req.purchase_date or date.today(),
    )
    db.add(asset)
    await db.commit()
    await db.refresh(asset)
    return asset


@router.delete("/{asset_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_precious_metal_asset(
    asset_id: UUID, db: AsyncSession = Depends(get_db)
):
    stmt = select(PreciousMetalAsset).where(PreciousMetalAsset.id == asset_id)
    res = await db.execute(stmt)
    asset = res.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=404, detail="Precious Metal asset not found")
    await db.delete(asset)
    await db.commit()
    return None
