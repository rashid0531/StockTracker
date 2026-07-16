from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import User, ViewUserStockHolding
from app.schemas import UserDividendProjectionsResponse

router = APIRouter(prefix="/holdings", tags=["Holdings"])


@router.get("/projections/{user_id}", response_model=UserDividendProjectionsResponse)
async def get_dividend_projections(user_id: UUID, db: AsyncSession = Depends(get_db)):
    """Fetch projected cumulative annual dividends aggregated per profile and

    categorized by their native currencies for a given user.
    """
    # 1. Validate if user exists
    user_exists_stmt = select(User).where(User.id == user_id)
    user_exists_res = await db.execute(user_exists_stmt)
    user = user_exists_res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # 2. Query view_user_stock_holdings and aggregate projections
    stmt = (
        select(
            ViewUserStockHolding.profile_id,
            ViewUserStockHolding.profile_name,
            ViewUserStockHolding.native_currency.label("currency"),
            func.sum(
                ViewUserStockHolding.total_shares
                * ViewUserStockHolding.annualized_dividend_per_share
            ).label("projected_annual_dividend"),
        )
        .where(ViewUserStockHolding.user_id == user_id)
        .group_by(
            ViewUserStockHolding.profile_id,
            ViewUserStockHolding.profile_name,
            ViewUserStockHolding.native_currency,
        )
    )

    result = await db.execute(stmt)
    projections = []
    for row in result.all():
        projections.append(
            {
                "profile_id": row.profile_id,
                "profile_name": row.profile_name,
                "currency": row.currency,
                # Round to 4 decimal places for precision
                "projected_annual_dividend": round(row.projected_annual_dividend, 4),
            }
        )

    return {"user_id": user_id, "projections": projections}
