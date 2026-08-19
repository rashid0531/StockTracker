from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.worker import run_market_data_ingestion, YFinanceClient
# TODO: Add admin auth dependency here later
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.post("/force-refresh-market-data")
async def force_refresh_market_data(
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    # We pass it to a background task so it doesn't block the HTTP response
    async def task_runner():
        async with db.bind.connect() as conn: # Better to use a fresh session in bg task
            pass # We'll create a fresh session inside
            
    # Actually, background_tasks in FastAPI run in the same event loop.
    # It's better to just spawn it properly with a new session.
    background_tasks.add_task(run_ingestion_task)
    return {"status": "accepted", "message": "Market data refresh triggered in background."}

async def run_ingestion_task():
    from app.database import AsyncSessionLocal
    logger.info("Admin triggered manual market data refresh")
    async with AsyncSessionLocal() as session:
        client = YFinanceClient()
        await run_market_data_ingestion(session, client)
