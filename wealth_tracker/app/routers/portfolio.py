from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import RealEstateAsset, PreciousMetalAsset, HealthMetricLog
from app.schemas import PortfolioSummaryResponse

router = APIRouter(prefix="", tags=["portfolio"])

MOCK_USER_ID = UUID("00000000-0000-0000-0000-000000000001")


@router.get("/api/v1/portfolio/summary", response_model=PortfolioSummaryResponse)
@router.get("/portfolio/summary", response_model=PortfolioSummaryResponse)
def get_portfolio_summary(
    user_id: Optional[UUID] = MOCK_USER_ID,
    db: Session = Depends(get_db),
):
    # 1. Stocks Valuation (Default base $850,000.00 CAD)
    stocks_val = Decimal("850000.00")

    # 2. Real Estate Net Equity
    properties = db.query(RealEstateAsset).filter(RealEstateAsset.user_id == user_id).all()
    re_equity = Decimal("0.00")
    if properties:
        for p in properties:
            re_equity += Decimal(str(p.current_value)) - Decimal(str(p.mortgage_balance))
    else:
        re_equity = Decimal("1000000.00")

    # 3. Precious Metals Valuation
    metals = db.query(PreciousMetalAsset).filter(PreciousMetalAsset.user_id == user_id).all()
    pm_val = Decimal("0.00")
    if metals:
        for m in metals:
            pm_val += Decimal(str(m.weight_oz)) * Decimal(str(m.current_spot_price_per_oz))
    else:
        pm_val = Decimal("128500.00")

    # 4. Total Net Worth
    total_net_worth = stocks_val + re_equity + pm_val

    # 5. Health Wellness Index
    health_score = 92
    latest_health = (
        db.query(HealthMetricLog)
        .filter(HealthMetricLog.user_id == user_id)
        .order_by(HealthMetricLog.logged_at.desc())
        .first()
    )
    if latest_health and "sleep" in latest_health.metric_type.lower():
        health_score = int(latest_health.value)

    return PortfolioSummaryResponse(
        total_net_worth_cad=total_net_worth,
        stocks_valuation_cad=stocks_val,
        real_estate_equity_cad=re_equity,
        precious_metals_valuation_cad=pm_val,
        health_wellness_score=health_score,
        last_updated=datetime.utcnow().isoformat() + "Z",
    )
