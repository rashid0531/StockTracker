from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import User, ViewUserStockHolding, InvestmentProfile, StockRegistry, FXHistoricalRate
from app.schemas import UserDividendProjectionsResponse, UserProfileValuesResponse

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


@router.get("/value/{user_id}", response_model=UserProfileValuesResponse)
async def get_profile_valuations(
    user_id: UUID,
    target_currency: str = "CAD",
    db: AsyncSession = Depends(get_db)
):
    """Fetch the overall current value of each investment profile for a user,

    converted to the specified target currency (e.g. CAD, USD).
    """
    # 1. Validate if user exists
    user_exists_stmt = select(User).where(User.id == user_id)
    user_exists_res = await db.execute(user_exists_stmt)
    user = user_exists_res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Ensure target currency is uppercase
    target_currency = target_currency.upper().strip()

    # 2. Get all investment profiles for the user to initialize totals
    profiles_stmt = select(InvestmentProfile).where(InvestmentProfile.user_id == user_id)
    profiles_res = await db.execute(profiles_stmt)
    profiles = profiles_res.scalars().all()

    profile_names = {p.id: p.name for p in profiles}
    profile_values = {p.id: Decimal("0.0000") for p in profiles}

    # 3. Fetch all active holdings with current stock prices
    holdings_stmt = (
        select(
            ViewUserStockHolding.profile_id,
            ViewUserStockHolding.native_currency,
            func.sum(ViewUserStockHolding.total_shares).label("total_shares"),
            StockRegistry.current_price,
        )
        .join(StockRegistry, ViewUserStockHolding.stock_id == StockRegistry.id)
        .where(ViewUserStockHolding.user_id == user_id)
        .group_by(
            ViewUserStockHolding.profile_id,
            ViewUserStockHolding.native_currency,
            StockRegistry.current_price,
        )
    )
    holdings_res = await db.execute(holdings_stmt)
    holdings = holdings_res.all()

    # 4. Fetch the latest FX rates from the database in a single query
    # Subquery to get the latest rate date per from/to pair
    subq = (
        select(
            FXHistoricalRate.from_currency,
            FXHistoricalRate.to_currency,
            func.max(FXHistoricalRate.rate_date).label("max_date"),
        )
        .group_by(FXHistoricalRate.from_currency, FXHistoricalRate.to_currency)
        .subquery()
    )

    fx_stmt = select(
        FXHistoricalRate.from_currency,
        FXHistoricalRate.to_currency,
        FXHistoricalRate.exchange_rate,
    ).join(
        subq,
        (FXHistoricalRate.from_currency == subq.c.from_currency)
        & (FXHistoricalRate.to_currency == subq.c.to_currency)
        & (FXHistoricalRate.rate_date == subq.c.max_date),
    )
    fx_res = await db.execute(fx_stmt)

    # Build lookup map: (from_currency, to_currency) -> exchange_rate
    rates_map = {
        (row.from_currency, row.to_currency): row.exchange_rate
        for row in fx_res.all()
    }

    # Helper function to resolve exchange rate
    def resolve_fx_rate(from_curr: str, to_curr: str) -> Decimal:
        if from_curr == to_curr:
            return Decimal("1.0")
        # Direct rate
        if (from_curr, to_curr) in rates_map:
            return rates_map[(from_curr, to_curr)]
        # Inverse rate
        if (to_curr, from_curr) in rates_map:
            return Decimal("1.0") / rates_map[(to_curr, from_curr)]
        # Fallback to 1.0
        return Decimal("1.0")

    # 5. Convert and aggregate values per profile
    for row in holdings:
        stock_curr = row.native_currency.upper().strip()
        shares = row.total_shares
        price = row.current_price

        # Resolve the conversion rate from stock native currency to user target currency
        rate = resolve_fx_rate(stock_curr, target_currency)

        value_in_target = shares * price * rate
        if row.profile_id in profile_values:
            profile_values[row.profile_id] += value_in_target

    # 6. Build response profiles list
    profile_list = [
        {
            "profile_id": pid,
            "profile_name": profile_names[pid],
            "total_value": round(profile_values[pid], 4),
        }
        for pid in profile_values
    ]

    return {
        "user_id": user_id,
        "target_currency": target_currency,
        "profiles": profile_list,
    }
