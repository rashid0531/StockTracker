from typing import Optional
from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import User, ViewUserStockHolding, InvestmentProfile, StockRegistry, FXHistoricalRate, DividendSchedule, UserStockThesis, StockTransaction, BrokerageAccount
from app.schemas import (
    UserDividendProjectionsResponse,
    UserProfileValuesResponse,
    UserDividendCalendarResponse,
    ThesisCreateUpdate,
    ThesisResponse,
    TransactionCreateRequest,
    TransactionItemResponse,
    UserTransactionsResponse,
    ProfileCreate,
    ProfileResponse,
)

router = APIRouter(prefix="/holdings", tags=["Holdings"])


@router.post("/profiles/", response_model=ProfileResponse)
async def create_profile(body: ProfileCreate, db: AsyncSession = Depends(get_db)):
    profile = InvestmentProfile(
        user_id=body.user_id,
        name=body.name,
        country=body.country,
        account_type=body.account_type,
        pillar_category=body.pillar_category,
    )
    db.add(profile)
    await db.commit()
    await db.refresh(profile)
    return profile


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

    profile_info = {p.id: p for p in profiles}
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
            "profile_name": profile_info[pid].name,
            "country": profile_info[pid].country,
            "account_type": profile_info[pid].account_type,
            "total_value": round(profile_values[pid], 4),
        }
        for pid in profile_values
    ]

    return {
        "user_id": user_id,
        "target_currency": target_currency,
        "profiles": profile_list,
    }


# Phase 1: Dividend Calendar Endpoint
@router.get("/dividends/calendar/{user_id}", response_model=UserDividendCalendarResponse)
async def get_dividend_calendar(user_id: UUID, db: AsyncSession = Depends(get_db)):
    """Fetch ex-dividend and payment schedules for all stocks currently held by the user."""
    # 1. Fetch user's active holdings
    holdings_stmt = select(ViewUserStockHolding).where(ViewUserStockHolding.user_id == user_id)
    holdings_res = await db.execute(holdings_stmt)
    holdings = holdings_res.scalars().all()

    # Map stock_id -> total_shares
    stock_shares = {}
    for h in holdings:
        stock_shares[h.stock_id] = stock_shares.get(h.stock_id, Decimal("0.0")) + h.total_shares

    if not stock_shares:
        return {"user_id": user_id, "events": []}

    # 2. Query dividend schedule for these stocks
    schedule_stmt = (
        select(DividendSchedule, StockRegistry)
        .join(StockRegistry, DividendSchedule.stock_id == StockRegistry.id)
        .where(DividendSchedule.stock_id.in_(list(stock_shares.keys())))
        .order_by(DividendSchedule.payment_date.asc())
    )
    schedule_res = await db.execute(schedule_stmt)

    events = []
    for schedule, stock in schedule_res.all():
        shares = stock_shares[stock.id]
        projected_payout = shares * schedule.amount_per_share
        events.append({
            "ticker": stock.ticker,
            "stock_name": stock.name,
            "ex_dividend_date": schedule.ex_dividend_date,
            "payment_date": schedule.payment_date,
            "amount_per_share": schedule.amount_per_share,
            "shares_owned": shares,
            "projected_payout": projected_payout,
            "currency": stock.currency
        })

    return {"user_id": user_id, "events": events}


# Phase 1: Investment Thesis Journaling Endpoints
@router.get("/theses/{user_id}/{stock_id}", response_model=ThesisResponse)
async def get_investment_thesis(user_id: UUID, stock_id: UUID, db: AsyncSession = Depends(get_db)):
    """Fetch the investment thesis for a user's stock holding."""
    stmt = select(UserStockThesis).where(
        UserStockThesis.user_id == user_id,
        UserStockThesis.stock_id == stock_id
    )
    result = await db.execute(stmt)
    thesis = result.scalar_one_or_none()
    if not thesis:
        raise HTTPException(status_code=404, detail="Thesis not found")

    # Determine if a review is needed (outdated after review_interval_days)
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc)
    delta = now - thesis.last_reviewed_at
    needs_review = delta.days >= thesis.review_interval_days

    return {
        "stock_id": thesis.stock_id,
        "thesis_text": thesis.thesis_text,
        "review_interval_days": thesis.review_interval_days,
        "last_reviewed_at": thesis.last_reviewed_at,
        "updated_at": thesis.updated_at,
        "needs_review": needs_review
    }


@router.post("/theses", response_model=ThesisResponse)
async def create_or_update_investment_thesis(body: ThesisCreateUpdate, db: AsyncSession = Depends(get_db)):
    """Create or update (upsert) the investment thesis for a specific stock holding."""
    from sqlalchemy.dialects.postgresql import insert
    
    stmt = insert(UserStockThesis).values(
        user_id=body.user_id,
        stock_id=body.stock_id,
        thesis_text=body.thesis_text,
        review_interval_days=body.review_interval_days or 180,
        last_reviewed_at=func.now(),
        updated_at=func.now()
    )
    stmt = stmt.on_conflict_do_update(
        constraint="uq_user_stock_thesis",
        set_={
            "thesis_text": stmt.excluded.thesis_text,
            "review_interval_days": stmt.excluded.review_interval_days,
            "last_reviewed_at": func.now(),
            "updated_at": func.now()
        }
    )
    await db.execute(stmt)
    await db.commit()

    # Retrieve and return the updated thesis
    select_stmt = select(UserStockThesis).where(
        UserStockThesis.user_id == body.user_id,
        UserStockThesis.stock_id == body.stock_id
    )
    res = await db.execute(select_stmt)
    thesis = res.scalar_one()

    return {
        "stock_id": thesis.stock_id,
        "thesis_text": thesis.thesis_text,
        "review_interval_days": thesis.review_interval_days,
        "last_reviewed_at": thesis.last_reviewed_at,
        "updated_at": thesis.updated_at,
        "needs_review": False
    }


@router.post("/transactions", response_model=TransactionItemResponse)
async def create_stock_transaction(body: TransactionCreateRequest, db: AsyncSession = Depends(get_db)):
    """Record a new BUY or SELL stock transaction."""
    from datetime import datetime, timezone

    # 1. Validate profile existence
    profile_stmt = select(InvestmentProfile).where(InvestmentProfile.id == body.profile_id)
    profile_res = await db.execute(profile_stmt)
    profile = profile_res.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Investment profile not found")

    # 2. Get or create brokerage account for profile
    account_stmt = select(BrokerageAccount).where(BrokerageAccount.profile_id == body.profile_id)
    account_res = await db.execute(account_stmt)
    account = account_res.scalars().first()
    if not account:
        account = BrokerageAccount(profile_id=body.profile_id, broker_name="Default Brokerage")
        db.add(account)
        await db.flush()

    # 3. Resolve stock in registry
    ticker_upper = body.ticker.strip().upper()
    stock_stmt = select(StockRegistry).where(StockRegistry.ticker == ticker_upper)
    stock_res = await db.execute(stock_stmt)
    stock = stock_res.scalar_one_or_none()
    if not stock:
        stock = StockRegistry(
            ticker=ticker_upper,
            name=f"{ticker_upper} Holding",
            exchange="TSX" if body.currency == "CAD" else "NASDAQ",
            country="Canada" if body.currency == "CAD" else "USA",
            currency=body.currency,
            current_price=body.price_per_share,
            annualized_dividend_per_share=Decimal("0.0000"),
        )
        db.add(stock)
        await db.flush()

    # 4. Insert transaction
    tx_date = datetime.now(timezone.utc)
    if body.transaction_date:
        try:
            tx_date = datetime.fromisoformat(body.transaction_date)
        except Exception:
            pass

    tx = StockTransaction(
        account_id=account.id,
        stock_id=stock.id,
        transaction_date=tx_date,
        transaction_type=body.transaction_type.upper(),
        quantity=body.quantity,
        price_per_share=body.price_per_share,
        currency=body.currency,
    )
    db.add(tx)
    await db.commit()
    await db.refresh(tx)

    total_amount = body.quantity * body.price_per_share

    return {
        "id": tx.id,
        "profile_id": profile.id,
        "profile_name": profile.name,
        "ticker": stock.ticker,
        "stock_name": stock.name,
        "transaction_type": tx.transaction_type,
        "quantity": tx.quantity,
        "price_per_share": tx.price_per_share,
        "total_amount": total_amount,
        "currency": tx.currency,
        "transaction_date": tx.transaction_date.strftime("%Y-%m-%d"),
    }


@router.get("/transactions/{user_id}", response_model=UserTransactionsResponse)
async def get_user_transactions(
    user_id: UUID,
    profile_id: Optional[UUID] = None,
    type: Optional[str] = None,
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    """Fetch all executed stock transactions for a user with optional filters."""
    stmt = (
        select(
            StockTransaction.id,
            InvestmentProfile.id.label("profile_id"),
            InvestmentProfile.name.label("profile_name"),
            StockRegistry.ticker,
            StockRegistry.name.label("stock_name"),
            StockTransaction.transaction_type,
            StockTransaction.quantity,
            StockTransaction.price_per_share,
            StockTransaction.currency,
            StockTransaction.transaction_date,
        )
        .join(BrokerageAccount, StockTransaction.account_id == BrokerageAccount.id)
        .join(InvestmentProfile, BrokerageAccount.profile_id == InvestmentProfile.id)
        .join(StockRegistry, StockTransaction.stock_id == StockRegistry.id)
        .where(InvestmentProfile.user_id == user_id)
        .order_by(StockTransaction.transaction_date.desc())
    )

    if profile_id:
        stmt = stmt.where(InvestmentProfile.id == profile_id)
    if type and type.upper() in ["BUY", "SELL"]:
        stmt = stmt.where(StockTransaction.transaction_type == type.upper())
    if search:
        search_fmt = f"%{search.strip()}%"
        stmt = stmt.where(
            (StockRegistry.ticker.ilike(search_fmt)) | (StockRegistry.name.ilike(search_fmt))
        )

    res = await db.execute(stmt)
    rows = res.all()

    tx_list = []
    for r in rows:
        total = Decimal(str(r.quantity)) * Decimal(str(r.price_per_share))
        date_str = r.transaction_date.strftime("%Y-%m-%d") if r.transaction_date else ""
        tx_list.append(
            {
                "id": r.id,
                "profile_id": r.profile_id,
                "profile_name": r.profile_name,
                "ticker": r.ticker,
                "stock_name": r.stock_name,
                "transaction_type": r.transaction_type,
                "quantity": r.quantity,
                "price_per_share": r.price_per_share,
                "total_amount": total,
                "currency": r.currency,
                "transaction_date": date_str,
            }
        )

    return {"user_id": user_id, "transactions": tx_list}


