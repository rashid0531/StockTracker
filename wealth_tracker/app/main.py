from fastapi import FastAPI
from app.logger import setup_logging
setup_logging()

from fastapi.middleware.cors import CORSMiddleware

from app.routers import holdings, admin, users, real_estate, precious_metals, health, portfolio, ai_suggestions

from contextlib import asynccontextmanager
from app.services.cache import cache_service
from app.services.scheduler import start_scheduler, shutdown_scheduler

@asynccontextmanager
async def lifespan(app: FastAPI):
    await cache_service.connect()
    start_scheduler()
    yield
    shutdown_scheduler()
    await cache_service.disconnect()

app = FastAPI(
    title="Wealth & Dividend Tracking Engine",
    description="Production-grade backend engine for tracking financial, real estate, physical metals, and health assets",
    version="1.0.0",
    lifespan=lifespan
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(portfolio.router)
app.include_router(holdings.router)
app.include_router(real_estate.router)
app.include_router(precious_metals.router)
app.include_router(health.router)
app.include_router(ai_suggestions.router)
app.include_router(admin.router)
app.include_router(users.router)


@app.get("/")
async def root():
    return {
        "status": "online",
        "message": "Wealth & Dividend Tracking Engine is active.",
    }


