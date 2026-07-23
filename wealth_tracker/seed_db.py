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
    DividendSchedule,
    UserStockThesis,
)
from app.worker import YFinanceClient, run_market_data_ingestion

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("seed_db")


async def clear_db(session: AsyncSession):
    logger.info("Clearing existing data from database...")
    await session.execute(delete(UserStockThesis))
    await session.execute(delete(DividendSchedule))
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
        primary_country="Canada",
        primary_currency="CAD",
    )
    session.add(user)

    # 2. Create investment profiles
    tfsa_profile = InvestmentProfile(
        id=uuid.UUID("a9117be5-4ea5-419f-b778-be75b22b271d"),
        user=user,
        name="TFSA Account",
        country="Canada",
        account_type="TFSA (Tax-Free Savings Account)",
    )
    rrsp_profile = InvestmentProfile(
        id=uuid.UUID("f90117d3-9bc0-4c28-98e3-4de75b2b271e"),
        user=user,
        name="RRSP Ledger",
        country="Canada",
        account_type="RRSP (Registered Retirement Savings Plan)",
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
    tfsa_stocks_data = [
        ("AAPL", "Apple Inc.", "USD", 185.00, 0.96),
        ("XIU", "iShares S&P/TSX 60 ETF", "CAD", 32.50, 0.98),
        ("SHOP", "Shopify Inc.", "CAD", 95.00, 0.00),
        ("RY", "Royal Bank of Canada", "CAD", 140.00, 5.60),
        ("TD", "Toronto-Dominion Bank", "CAD", 85.00, 4.08),
        ("CNR", "Canadian National Railway", "CAD", 165.00, 3.36),
        ("ENB", "Enbridge Inc.", "CAD", 48.00, 3.66),
        ("CNQ", "Canadian Natural Resources", "CAD", 90.00, 4.00),
        ("CP", "Canadian Pacific Kansas City", "CAD", 115.00, 0.76),
        ("BNS", "Bank of Nova Scotia", "CAD", 65.00, 4.24),
        ("BMO", "Bank of Montreal", "CAD", 120.00, 6.00),
        ("BAM", "Brookfield Asset Management", "CAD", 50.00, 1.52),
        ("SLF", "Sun Life Financial Inc.", "CAD", 70.00, 3.20),
        ("ATD", "Alimentation Couche-Tard", "CAD", 78.00, 0.70),
        ("NTR", "Nutrien Ltd.", "CAD", 75.00, 2.16),
        ("CSU", "Constellation Software", "CAD", 3600.00, 4.00),
        ("WCN", "Waste Connections Inc.", "CAD", 220.00, 1.15),
        ("L", "Loblaw Companies Limited", "CAD", 145.00, 1.88),
        ("FNV", "Franco-Nevada Corporation", "CAD", 160.00, 1.36),
        ("WPM", "Wheaton Precious Metals", "CAD", 65.00, 0.60),
        ("MG", "Magna International Inc.", "CAD", 55.00, 1.88),
        ("IMO", "Imperial Oil Limited", "CAD", 85.00, 2.40),
        ("CVE", "Cenovus Energy Inc.", "CAD", 25.00, 0.72),
        ("GIB.A", "CGI Inc.", "CAD", 140.00, 0.00),
        ("TECK.B", "Teck Resources Limited", "CAD", 60.00, 0.50),
        ("POW", "Power Corporation of Canada", "CAD", 38.00, 2.10),
        ("EMA", "Emera Incorporated", "CAD", 45.00, 2.87),
        ("FTS", "Fortis Inc.", "CAD", 54.00, 2.36),
        ("AEM", "Agnico Eagle Mines Limited", "CAD", 80.00, 1.60),
        ("MFC", "Manulife Financial Corp.", "CAD", 32.00, 1.60),
        ("QSR", "Restaurant Brands Intl", "CAD", 98.00, 2.32),
        ("H", "Hydro One Limited", "CAD", 40.00, 1.20),
        ("GIL", "Gildan Activewear Inc.", "CAD", 48.00, 0.82),
        ("OTEX", "Open Text Corporation", "CAD", 42.00, 1.00),
        ("DOL", "Dollarama Inc.", "CAD", 110.00, 0.30),
    ]

    rrsp_stocks_data = [
        ("BHP", "BHP Group Limited", "AUD", 43.00, 2.40),
        ("BP", "BP plc", "GBP", 4.80, 0.28),
        ("MSFT", "Microsoft Corporation", "USD", 420.00, 3.00),
        ("JNJ", "Johnson & Johnson", "USD", 155.00, 4.96),
        ("PG", "Procter & Gamble Co.", "USD", 160.00, 4.03),
        ("KO", "The Coca-Cola Company", "USD", 62.00, 1.94),
        ("PEP", "PepsiCo, Inc.", "USD", 170.00, 5.42),
        ("JPM", "JPMorgan Chase & Co.", "USD", 195.00, 4.60),
        ("XOM", "Exxon Mobil Corporation", "USD", 115.00, 3.80),
        ("CVX", "Chevron Corporation", "USD", 150.00, 6.52),
        ("MRK", "Merck & Co., Inc.", "USD", 125.00, 3.08),
        ("ABBV", "AbbVie Inc.", "USD", 175.00, 6.20),
        ("MCD", "McDonald's Corporation", "USD", 280.00, 6.68),
        ("PFE", "Pfizer Inc.", "USD", 28.00, 1.68),
        ("VZ", "Verizon Communications", "USD", 40.00, 2.66),
        ("T", "AT&T Inc.", "USD", 18.00, 1.11),
        ("HD", "Home Depot, Inc.", "USD", 350.00, 9.00),
        ("LOW", "Lowe's Companies, Inc.", "USD", 220.00, 4.40),
        ("MMM", "3M Company", "USD", 95.00, 6.04),
        ("CAT", "Caterpillar Inc.", "USD", 330.00, 5.20),
        ("DE", "Deere & Company", "USD", 380.00, 5.88),
        ("HON", "Honeywell International", "USD", 200.00, 4.32),
        ("GE", "General Electric Company", "USD", 150.00, 1.12),
        ("IBM", "IBM Corporation", "USD", 185.00, 6.68),
        ("CSCO", "Cisco Systems, Inc.", "USD", 48.00, 1.60),
        ("TXN", "Texas Instruments Inc.", "USD", 175.00, 5.20),
        ("PM", "Philip Morris International", "USD", 95.00, 5.20),
        ("MO", "Altria Group, Inc.", "USD", 45.00, 3.92),
        ("NKE", "NIKE, Inc.", "USD", 95.00, 1.48),
        ("SBUX", "Starbucks Corporation", "USD", 85.00, 2.28),
        ("Target", "Target Corporation", "USD", 145.00, 4.40),
        ("CVS", "CVS Health Corporation", "USD", 75.00, 2.66),
        ("WMT", "Walmart Inc.", "USD", 60.00, 0.83),
        ("MDT", "Medtronic plc", "USD", 80.00, 2.76),
        ("BAC", "Bank of America Corp.", "USD", 38.00, 0.96),
    ]

    predefined_ids = {
        "AAPL": uuid.UUID("a7be54ea-5419-fb77-8be7-5b22b271db11"),
        "XIU": uuid.UUID("b7be54ea-5419-fb77-8be7-5b22b271db22"),
        "BHP": uuid.UUID("c7be54ea-5419-fb77-8be7-5b22b271db33"),
        "BP": uuid.UUID("d7be54ea-5419-fb77-8be7-5b22b271db44"),
    }

    all_stocks_data = tfsa_stocks_data + rrsp_stocks_data
    seen_tickers = set()
    unique_stocks_data = []
    for s in all_stocks_data:
        if s[0] not in seen_tickers:
            seen_tickers.add(s[0])
            unique_stocks_data.append(s)

    stock_map = {}
    for ticker, name, currency, price, div in unique_stocks_data:
        if ticker in predefined_ids:
            stock_id = predefined_ids[ticker]
        else:
            stock_id = uuid.uuid5(uuid.NAMESPACE_DNS, ticker)

        exchange = "TSX" if currency == "CAD" else "NASDAQ"
        if currency == "AUD":
            exchange = "ASX"
        elif currency == "GBP":
            exchange = "LSE"

        country = "Canada" if currency == "CAD" else "USA"
        if currency == "AUD":
            country = "Australia"
        elif currency == "GBP":
            country = "UK"

        stock = StockRegistry(
            id=stock_id,
            ticker=ticker,
            name=name,
            exchange=exchange,
            country=country,
            currency=currency,
            current_price=Decimal(str(price)),
            annualized_dividend_per_share=Decimal(str(div)),
        )
        session.add(stock)
        stock_map[ticker] = stock

    aapl = stock_map["AAPL"]
    xiu = stock_map["XIU"]
    bhp = stock_map["BHP"]
    bp = stock_map["BP"]

    # 5. Create FX rates
    fx_rates = [
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
    tfsa_shares = {
        "AAPL": 12.0, "XIU": 150.0, "SHOP": 10.0, "RY": 20.0, "TD": 30.0,
        "CNR": 15.0, "ENB": 80.0, "CNQ": 40.0, "CP": 25.0, "BNS": 35.0,
        "BMO": 18.0, "BAM": 50.0, "SLF": 22.0, "ATD": 30.0, "NTR": 20.0,
        "CSU": 1.0, "WCN": 8.0, "L": 12.0, "FNV": 10.0, "WPM": 25.0,
        "MG": 40.0, "IMO": 15.0, "CVE": 100.0, "GIB.A": 15.0, "TECK.B": 30.0,
        "POW": 50.0, "EMA": 40.0, "FTS": 60.0, "AEM": 20.0, "MFC": 120.0,
        "QSR": 25.0, "H": 50.0, "GIL": 30.0, "OTEX": 45.0, "DOL": 25.0
    }

    rrsp_shares = {
        "BHP": 50.5, "BP": 200.75, "MSFT": 15.0, "JNJ": 40.0, "PG": 35.0,
        "KO": 100.0, "PEP": 30.0, "JPM": 25.0, "XOM": 50.0, "CVX": 20.0,
        "MRK": 45.0, "ABBV": 30.0, "MCD": 12.0, "PFE": 150.0, "VZ": 120.0,
        "T": 200.0, "HD": 10.0, "LOW": 15.0, "MMM": 25.0, "CAT": 8.0,
        "DE": 6.0, "HON": 12.0, "GE": 25.0, "IBM": 18.0, "CSCO": 75.0,
        "TXN": 14.0, "PM": 40.0, "MO": 90.0, "NKE": 20.0, "SBUX": 30.0,
        "Target": 25.0, "CVS": 35.0, "WMT": 50.0, "MDT": 30.0, "BAC": 80.0
    }

    for ticker, shares in tfsa_shares.items():
        stock = stock_map[ticker]
        fx = Decimal("1.35") if stock.currency == "USD" else Decimal("1.0")
        t = StockTransaction(
            account=questrade_tfsa,
            stock=stock,
            transaction_date=datetime.datetime(2026, 1, 15, 10, 0, tzinfo=datetime.timezone.utc),
            transaction_type="BUY",
            quantity=Decimal(str(shares)),
            price_per_share=stock.current_price,
            currency=stock.currency,
            fx_rate=fx,
        )
        session.add(t)

    for ticker, shares in rrsp_shares.items():
        stock = stock_map[ticker]
        fx = Decimal("1.0")
        if stock.currency == "AUD":
            fx = Decimal("0.90")
        elif stock.currency == "GBP":
            fx = Decimal("1.72")
        elif stock.currency == "USD":
            fx = Decimal("1.35")
            
        t = StockTransaction(
            account=wealthsimple_rrsp,
            stock=stock,
            transaction_date=datetime.datetime(2026, 1, 15, 10, 0, tzinfo=datetime.timezone.utc),
            transaction_type="BUY",
            quantity=Decimal(str(shares)),
            price_per_share=stock.current_price,
            currency=stock.currency,
            fx_rate=fx,
        )
        session.add(t)

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

    # 8. Create mock dividend schedules (Phase 1)
    ds1 = DividendSchedule(
        stock=aapl,
        ex_dividend_date=datetime.date(2026, 7, 28),
        payment_date=datetime.date(2026, 8, 14),
        amount_per_share=Decimal("0.24"),
    )
    ds2 = DividendSchedule(
        stock=xiu,
        ex_dividend_date=datetime.date(2026, 7, 30),
        payment_date=datetime.date(2026, 8, 7),
        amount_per_share=Decimal("0.25"),
    )
    ds3 = DividendSchedule(
        stock=bhp,
        ex_dividend_date=datetime.date(2026, 8, 10),
        payment_date=datetime.date(2026, 9, 2),
        amount_per_share=Decimal("1.20"),
    )
    ds4 = DividendSchedule(
        stock=bp,
        ex_dividend_date=datetime.date(2026, 8, 15),
        payment_date=datetime.date(2026, 9, 20),
        amount_per_share=Decimal("0.07"),
    )
    session.add_all([ds1, ds2, ds3, ds4])

    # 9. Create a mock investment thesis (Phase 1)
    # January 15, 2026 is >180 days before July 21, 2026, triggering review warning
    thesis = UserStockThesis(
        user_id=user.id,
        stock=aapl,
        thesis_text="Apple has a dominant ecosystem, strong services growth, and robust buyback program. High free cash flow generation makes its dividend extremely secure and likely to grow at 5-10% annually.",
        review_interval_days=180,
        last_reviewed_at=datetime.datetime(2026, 1, 15, 12, 0, tzinfo=datetime.timezone.utc),
        created_at=datetime.datetime(2026, 1, 15, 12, 0, tzinfo=datetime.timezone.utc),
        updated_at=datetime.datetime(2026, 1, 15, 12, 0, tzinfo=datetime.timezone.utc),
    )
    session.add(thesis)

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
