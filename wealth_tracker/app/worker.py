import abc
import asyncio
import logging
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession
import yfinance as yf
from yahooquery import Ticker as YQTicker

from app.models import DailyStockPrice, StockRegistry

logger = logging.getLogger("market_data_worker")
logging.basicConfig(level=logging.INFO)


# Strategy Design Pattern interface
class BaseMarketDataClient(abc.ABC):

    @abc.abstractmethod
    async def fetch_stock_data(self, ticker: str) -> Optional[Dict[str, Any]]:
        """Fetch stock metadata, daily adjusted close prices, and split events.

        Returns:
            Dict containing:
                - "current_price": Decimal
                - "annualized_dividend": Decimal
                - "historical_prices": List[Dict[str, Any]] (trading_date: date,
                adj_close_price: Decimal)
                - "splits": List[Dict[str, Any]] (date: date, ratio: Decimal)
        """
        pass


class YFinanceClient(BaseMarketDataClient):

    async def fetch_stock_data(self, ticker: str) -> Optional[Dict[str, Any]]:
        def sync_fetch():
            logger.info(f"[yfinance] Fetching data for {ticker}")
            stock = yf.Ticker(ticker)
            history = stock.history(period="1mo")
            info = stock.info
            splits = stock.splits
            return info, history, splits

        try:
            info, history, splits = await asyncio.to_thread(sync_fetch)
            if not info or history.empty:
                logger.warning(f"[yfinance] No info or history found for {ticker}")
                return None

            current_price = (
                info.get("currentPrice")
                or info.get("regularMarketPrice")
                or info.get("previousClose")
            )
            if current_price is None:
                current_price = history["Close"].iloc[-1]

            dividend_rate = (
                info.get("dividendRate")
                or info.get("trailingAnnualDividendRate")
                or 0.0
            )

            historical_prices = []
            for timestamp, row in history.iterrows():
                historical_prices.append(
                    {
                        "trading_date": timestamp.date(),
                        "adj_close_price": Decimal(str(round(row["Close"], 4))),
                    }
                )

            splits_list = []
            if not splits.empty:
                for timestamp, ratio in splits.items():
                    splits_list.append(
                        {
                            "date": timestamp.date(),
                            "ratio": Decimal(str(ratio)),
                        }
                    )

            return {
                "current_price": Decimal(str(round(current_price, 4))),
                "annualized_dividend": Decimal(str(round(dividend_rate, 4))),
                "historical_prices": historical_prices,
                "splits": splits_list,
            }
        except Exception as e:
            logger.error(
                f"[yfinance] Error fetching data for {ticker}: {str(e)}",
                exc_info=True,
            )
            return None


class YahooQueryClient(BaseMarketDataClient):

    async def fetch_stock_data(self, ticker: str) -> Optional[Dict[str, Any]]:
        def sync_fetch():
            logger.info(f"[yahooquery] Fetching data for {ticker}")
            yq = YQTicker(ticker)
            price_data = yq.price
            summary_detail = yq.summary_detail
            history = yq.history(period="1mo")
            return price_data, summary_detail, history

        try:
            price_data, summary_detail, history = await asyncio.to_thread(
                sync_fetch
            )

            if isinstance(price_data, str) or (
                isinstance(price_data, dict) and ticker not in price_data
            ):
                logger.warning(f"[yahooquery] Error or no price data for {ticker}")
                return None

            ticker_price = price_data.get(ticker, {})
            if isinstance(ticker_price, str):
                logger.warning(
                    f"[yahooquery] Error string returned for {ticker}: {ticker_price}"
                )
                return None

            current_price = ticker_price.get(
                "regularMarketPrice"
            ) or ticker_price.get("regularMarketPreviousClose")

            ticker_summary = (
                summary_detail.get(ticker, {})
                if isinstance(summary_detail, dict)
                else {}
            )
            if isinstance(ticker_summary, str):
                ticker_summary = {}
            dividend_rate = (
                ticker_summary.get("dividendRate")
                or ticker_summary.get("trailingAnnualDividendRate")
                or 0.0
            )

            if history is None or history.empty:
                logger.warning(f"[yahooquery] History was empty for {ticker}")
                return None

            historical_prices = []
            splits_list = []

            # Determine index type
            if history.index.nlevels > 1:
                # MultiIndex: (symbol, date)
                for (sym, d), row in history.iterrows():
                    d_parsed = (
                        d.date()
                        if hasattr(d, "date")
                        else datetime.strptime(str(d), "%Y-%m-%d").date()
                    )
                    adj_close = row.get("adjclose") or row.get("close")
                    historical_prices.append(
                        {
                            "trading_date": d_parsed,
                            "adj_close_price": Decimal(str(round(adj_close, 4))),
                        }
                    )
                    ratio = row.get("splits", 0.0)
                    if ratio and ratio > 0.0 and ratio != 1.0:
                        splits_list.append(
                            {"date": d_parsed, "ratio": Decimal(str(ratio))}
                        )
            else:
                for d, row in history.iterrows():
                    d_parsed = (
                        d.date()
                        if hasattr(d, "date")
                        else datetime.strptime(str(d), "%Y-%m-%d").date()
                    )
                    adj_close = row.get("adjclose") or row.get("close")
                    historical_prices.append(
                        {
                            "trading_date": d_parsed,
                            "adj_close_price": Decimal(str(round(adj_close, 4))),
                        }
                    )
                    ratio = row.get("splits", 0.0)
                    if ratio and ratio > 0.0 and ratio != 1.0:
                        splits_list.append(
                            {"date": d_parsed, "ratio": Decimal(str(ratio))}
                        )

            if current_price is None and historical_prices:
                current_price = float(historical_prices[-1]["adj_close_price"])

            if current_price is None:
                logger.warning(
                    f"[yahooquery] Could not resolve current price for {ticker}"
                )
                return None

            return {
                "current_price": Decimal(str(round(current_price, 4))),
                "annualized_dividend": Decimal(str(round(dividend_rate, 4))),
                "historical_prices": historical_prices,
                "splits": splits_list,
            }
        except Exception as e:
            logger.error(
                f"[yahooquery] Error fetching data for {ticker}: {str(e)}",
                exc_info=True,
            )
            return None


def map_ticker_suffix(ticker: str, exchange: str) -> str:
    ticker = ticker.strip()
    exchange = exchange.upper().strip()
    if exchange in ("TSX", "TORONTO"):
        if not ticker.endswith(".TO"):
            return f"{ticker}.TO"
    elif exchange in ("ASX", "AUSTRALIAN"):
        if not ticker.endswith(".AX"):
            return f"{ticker}.AX"
    elif exchange in ("LSE", "LONDON"):
        if not ticker.endswith(".L"):
            return f"{ticker}.L"
    return ticker


async def run_market_data_ingestion(
    session: AsyncSession, client: BaseMarketDataClient
):
    logger.info("Starting market data ingestion routine...")
    stmt = select(StockRegistry)
    result = await session.execute(stmt)
    stocks = result.scalars().all()

    if not stocks:
        logger.info("No stocks registered in database to update.")
        return

    for stock in stocks:
        try:
            mapped_ticker = map_ticker_suffix(stock.ticker, stock.exchange)
            logger.info(
                f"Processing {stock.ticker} (mapped: {mapped_ticker},"
                f" Exchange: {stock.exchange})"
            )

            data = await client.fetch_stock_data(mapped_ticker)
            if not data:
                logger.warning(f"Failed to fetch data for stock: {stock.ticker}")
                continue

            # Update Registry Current Price & Annualized Dividend
            stock.current_price = data["current_price"]
            stock.annualized_dividend_per_share = data["annualized_dividend"]
            session.add(stock)

            # Log if corporate actions (splits) were detected
            if data["splits"]:
                logger.info(
                    f"Splits detected for {stock.ticker}: {data['splits']}"
                )

            # Upsert daily prices
            for price_row in data["historical_prices"]:
                stmt_upsert = insert(DailyStockPrice).values(
                    stock_id=stock.id,
                    trading_date=price_row["trading_date"],
                    adj_close_price=price_row["adj_close_price"],
                )
                stmt_upsert = stmt_upsert.on_conflict_do_update(
                    constraint="uq_stock_date",
                    set_={"adj_close_price": stmt_upsert.excluded.adj_close_price},
                )
                await session.execute(stmt_upsert)

            await session.commit()
            logger.info(
                f"Successfully updated stock registry and daily prices for"
                f" {stock.ticker}"
            )
        except Exception as ex:
            await session.rollback()
            logger.error(
                f"Failed to ingest data for stock {stock.ticker}: {str(ex)}",
                exc_info=True,
            )

        # 2-second rate-limiting delay
        logger.info("Waiting 2 seconds to respect API limits...")
        await asyncio.sleep(2)

    logger.info("Finished market data ingestion routine.")
