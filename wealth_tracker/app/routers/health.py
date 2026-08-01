from datetime import date
from decimal import Decimal
from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import HealthMetricLog
from app.schemas import (
    HealthMetricCreateRequest,
    HealthMetricResponse,
    UserHealthMetricsResponse,
)

router = APIRouter(prefix="/health", tags=["Health Metrics"])


@router.get("/{user_id}", response_model=UserHealthMetricsResponse)
async def get_user_health_metrics(
    user_id: UUID, db: AsyncSession = Depends(get_db)
):
    stmt = (
        select(HealthMetricLog)
        .where(HealthMetricLog.user_id == user_id)
        .order_by(HealthMetricLog.logged_at.desc())
    )
    result = await db.execute(stmt)
    metrics = list(result.scalars().all())

    return UserHealthMetricsResponse(
        user_id=user_id,
        metrics=metrics,
    )


@router.post("", response_model=HealthMetricResponse, status_code=status.HTTP_201_CREATED)
async def create_health_metric(
    req: HealthMetricCreateRequest, db: AsyncSession = Depends(get_db)
):
    metric = HealthMetricLog(
        user_id=req.user_id,
        metric_type=req.metric_type,
        value=req.value,
        unit=req.unit,
        notes=req.notes,
        logged_at=req.logged_at or date.today(),
    )
    db.add(metric)
    await db.commit()
    await db.refresh(metric)
    return metric


@router.delete("/{metric_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_health_metric(
    metric_id: UUID, db: AsyncSession = Depends(get_db)
):
    stmt = select(HealthMetricLog).where(HealthMetricLog.id == metric_id)
    res = await db.execute(stmt)
    metric = res.scalar_one_or_none()
    if not metric:
        raise HTTPException(status_code=404, detail="Health metric not found")
    await db.delete(metric)
    await db.commit()
    return None
