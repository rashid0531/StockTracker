import asyncio
import datetime
from decimal import Decimal
import logging
import uuid

from sqlalchemy import delete, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal, engine
from app.models import (
    BrokerageAccount,
    CompressedHistoricalBalance,
    DailyStockPrice,
    FXHistoricalRate,
    InvestmentProfile,
    StockRegistry,
    StockTransaction,
    User,
    ViewUserStockHolding,
)
from app.worker import YFinanceClient, run_market_data_ingestion

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("seed_db")


async def clear_db(session: AsyncSession):
    logger.info("Clearing existing data from database...")
    await session.execute(delete(DailyStockPrice))
    await session.execute(delete(StockTransaction))
    await session.execute(delete(CompressedHistoricalBalance))
    await session.execute(delete(FXHistoricalRate))
    await session.execute(delete(StockRegistry))
    await session.execute(delete(BrokerageAccount))
    await session.execute(delete(InvestmentProfile))
    await session.execute(delete(User))
    await session.commit()
    logger.info("Database cleared.")


async def seed_data(session: AsyncSession):
    logger.info("Seeding data...")

    # 1. Create a user
    user = User(
        id=uuid.UUID("d0e34cbb-5820-4e1b-b384-cb9ef3a1b80c"),
        email="jane.doe@example.com",
        name="Jane Doe",
    )
    session.add(user)

    # 2. Create investment profiles
    tfsa_profile = InvestmentProfile(
        id=uuid.UUID("a9117be5-4ea5-419f-b778-be75b22b271d"),
        user=user,
        name="TFSA",
    )
    rrsp_profile = InvestmentProfile(
        id=uuid.UUID("f90117d3-9bc0-4c28-98e3-4de75b2b271e"),
        user=user,
        name="RRSP",
    )
    session.add_all([tfsa_profile, rrsp_profile])

    # 3. Create brokerage accounts
    questrade_tfsa = BrokerageAccount(
        id=uuid.UUID("117be54e-a541-9fb7-78be-75b22b271db1"),
        profile=tfsa_profile,
        broker_name="Questrade",
        account_number="Q-TFSA-12345",
    )
    wealthsimple_tfsa = BrokerageAccount(
        id=uuid.UUID("227be54e-a541-9fb7-78be-75b22b271db2"),
        profile=tfsa_profile,
        broker_name="Wealthsimple",
        account_number="WS-TFSA-54321",
    )
    wealthsimple_rrsp = BrokerageAccount(
        id=uuid.UUID("337be54e-a541-9fb7-78be-75b22b271db3"),
        profile=rrsp_profile,
        broker_name="Wealthsimple",
        account_number="WS-RRSP-98765",
    )
    rbc_rrsp = BrokerageAccount(
        id=uuid.UUID("447be54e-a541-9fb7-78be-75b22b271db4"),
        profile=rrsp_profile,
        broker_name="RBC Direct Investing",
        account_number="RBC-RRSP-11111",
    )
    session.add_all([questrade_tfsa, wealthsimple_tfsa, wealthsimple_rrsp, rbc_rrsp])

    # 4. Create stock registry entries
    # AAPL (US, USD, NASDAQ)
    aapl = StockRegistry(
        id=uuid.UUID("a7be54ea-5419-fb77-8be7-5b22b271db11"),
        ticker="AAPL",
        name="Apple Inc.",
        exchange="NASDAQ",
        country="USA",
        currency="USD",
        current_price=Decimal("185.00"),
        annualized_dividend_per_share=Decimal("0.96"),
    )
    # XIU (Canada, CAD, TSX)
    xiu = StockRegistry(
        id=uuid.UUID("b7be54ea-5419-fb77-8be7-5b22b271db22"),
        ticker="XIU",
        name="iShares S&P/TSX 60 Index ETF",
        exchange="TSX",
        country="Canada",
        currency="CAD",
        current_price=Decimal("32.50"),
        annualized_dividend_per_share=Decimal("0.98"),
    )
    # BHP (Australia, AUD, ASX)
    bhp = StockRegistry(
        id=uuid.UUID("c7be54ea-5419-fb77-8be7-5b22b271db33"),
        ticker="BHP",
        name="BHP Group Limited",
        exchange="ASX",
        country="Australia",
        currency="AUD",
        current_price=Decimal("43.00"),
        annualized_dividend_per_share=Decimal("2.40"),
    )
    # BP (UK, GBP, LSE)
    bp = StockRegistry(
        id=uuid.UUID("d7be54ea-5419-fb77-8be7-5b22b271db44"),
        ticker="BP",
        name="BP plc",
        exchange="LSE",
        country="UK",
        currency="GBP",
        current_price=Decimal("4.80"),
        annualized_dividend_per_share=Decimal("0.28"),
    )
    session.add_all([aapl, xiu, bhp, bp])

    # 5. Create FX rates
    fx_rates = [
        # CAD to USD and vice versa
        FXHistoricalRate(
            from_currency="CAD",
            to_currency="USD",
            exchange_rate=Decimal("0.7400"),
            rate_date=datetime.date(2026, 7, 15),
        ),
        FXHistoricalRate(
            from_currency="USD",
            to_currency="CAD",
            exchange_rate=Decimal("1.3500"),
            rate_date=datetime.date(2026, 7, 15),
        ),
        # AUD to CAD/USD
        FXHistoricalRate(
            from_currency="AUD",
            to_currency="CAD",
            exchange_rate=Decimal("0.9000"),
            rate_date=datetime.date(2026, 7, 15),
        ),
        FXHistoricalRate(
            from_currency="AUD",
            to_currency="USD",
            exchange_rate=Decimal("0.6600"),
            rate_date=datetime.date(2026, 7, 15),
        ),
        # GBP to CAD/USD
        FXHistoricalRate(
            from_currency="GBP",
            to_currency="CAD",
            exchange_rate=Decimal("1.7500"),
            rate_date=datetime.date(2026, 7, 15),
        ),
        FXHistoricalRate(
            from_currency="GBP",
            to_currency="USD",
            exchange_rate=Decimal("1.2800"),
            rate_date=datetime.date(2026, 7, 15),
        ),
    ]
    session.add_all(fx_rates)

    # 6. Create transactions (Hot Ledger)
    t1 = StockTransaction(
        account=questrade_tfsa,
        stock=aapl,
        transaction_date=datetime.datetime(
            2026, 1, 15, 10, 0, tzinfo=datetime.timezone.utc
        ),
        transaction_type="BUY",
        quantity=Decimal("10.5000"),
        price_per_share=Decimal("180.0000"),
        currency="USD",
        fx_rate=Decimal("1.3500"),
    )
    t2 = StockTransaction(
        account=wealthsimple_tfsa,
        stock=xiu,
        transaction_date=datetime.datetime(
            2026, 2, 10, 14, 30, tzinfo=datetime.timezone.utc
        ),
        transaction_type="BUY",
        quantity=Decimal("100.2500"),
        price_per_share=Decimal("31.2000"),
        currency="CAD",
        fx_rate=Decimal("1.0000"),
    )
    t3 = StockTransaction(
        account=wealthsimple_rrsp,
        stock=bhp,
        transaction_date=datetime.datetime(
            2026, 3, 1, 9, 45, tzinfo=datetime.timezone.utc
        ),
        transaction_type="BUY",
        quantity=Decimal("50.5000"),
        price_per_share=Decimal("41.5000"),
        currency="AUD",
        fx_rate=Decimal("0.9000"),
    )
    t4 = StockTransaction(
        account=rbc_rrsp,
        stock=bp,
        transaction_date=datetime.datetime(
            2026, 4, 12, 11, 15, tzinfo=datetime.timezone.utc
        ),
        transaction_type="BUY",
        quantity=Decimal("200.7500"),
        price_per_share=Decimal("4.6500"),
        currency="GBP",
        fx_rate=Decimal("1.7200"),
    )
    session.add_all([t1, t2, t3, t4])

    # 7. Create compressed historical balances (Cold storage rollup)
    # Adding a cold storage rollup for BHP older than 5 years to test UNION ALL view functionality
    c1 = CompressedHistoricalBalance(
        account=wealthsimple_rrsp,
        stock=bhp,
        balance_date=datetime.date(2020, 1, 1),
        quantity=Decimal("100.0000"),
        compressed_fx_rate=Decimal("0.8500"),
        currency="AUD",
    )
    session.add(c1)

    await session.commit()
    logger.info("Data seeded successfully.")


async def run_verification(session: AsyncSession):
    logger.info("Running verification queries...")

    # Query view_user_stock_holdings to check calculated share positions
    stmt = select(ViewUserStockHolding)
    result = await session.execute(stmt)
    holdings = result.scalars().all()

    logger.info("\n--- Live Holdings Summary (Unified View) ---")
    for row in holdings:
        logger.info(
            f"Profile: {row.profile_name} | Broker: {row.broker_name} | Ticker:"
            f" {row.ticker} | Total Shares: {row.total_shares:.4f} | Dividend/Sh:"
            f" {row.annualized_dividend_per_share:.4f} {row.native_currency}"
        )

    # Let's verify that BHP total shares = 150.5 (100.0 cold + 50.5 hot)
    bhp_row = next((r for r in holdings if r.ticker == "BHP"), None)
    if bhp_row:
        assert (
            bhp_row.total_shares == Decimal("150.5000")
        ), f"BHP shares expected 150.5000, got {bhp_row.total_shares}"
        logger.info(
            "\n[SUCCESS] View correctly merged cold storage (100 shares) and hot"
            " transactions (50.5 shares) for BHP!"
        )

    # Aggregated Dividend Projections per Profile
    stmt_proj = (
        select(
            ViewUserStockHolding.profile_name,
            ViewUserStockHolding.native_currency,
            func.sum(
                ViewUserStockHolding.total_shares
                * ViewUserStockHolding.annualized_dividend_per_share
            ).label("projected_annual_dividend"),
        )
        .group_by(
            ViewUserStockHolding.profile_name, ViewUserStockHolding.native_currency
        )
    )
    res_proj = await session.execute(stmt_proj)

    logger.info("\n--- Projected Annual Dividends Aggregated per Profile ---")
    for row in res_proj.all():
        logger.info(
            f"Profile: {row.profile_name} | Currency: {row.native_currency} |"
            f" Projected Dividend: {row.projected_annual_dividend:.4f}"
        )


async def main():
    async with AsyncSessionLocal() as session:
        # 1. Clear tables
        await clear_db(session)

        # 2. Seed static user/accounts/registry/transactions
        await seed_data(session)

        # 3. Test Ingestion Worker
        # Use YFinanceClient strategy to fetch live market prices and history
        logger.info("\n--- Starting Ingestion Worker Test ---")
        client = YFinanceClient()
        await run_market_data_ingestion(session, client)

        # 4. Verify View and Projections logic
        await run_verification(session)


if __name__ == "__main__":
    asyncio.run(main())
