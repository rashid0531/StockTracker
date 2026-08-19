from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.worker import run_market_data_ingestion, YFinanceClient
from app.database import AsyncSessionLocal
import logging

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()

async def scheduled_market_data_ingestion():
    logger.info("Running scheduled market data ingestion...")
    async with AsyncSessionLocal() as session:
        client = YFinanceClient()
        await run_market_data_ingestion(session, client)

def start_scheduler():
    # Run every 6 hours
    scheduler.add_job(
        scheduled_market_data_ingestion,
        "interval",
        hours=6,
        id="market_data_ingestion",
        replace_existing=True
    )
    scheduler.start()
    logger.info("APScheduler started.")

def shutdown_scheduler():
    scheduler.shutdown()
    logger.info("APScheduler shut down.")
