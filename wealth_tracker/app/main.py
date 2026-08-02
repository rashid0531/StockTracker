from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import holdings, real_estate, precious_metals, health, portfolio

app = FastAPI(
    title="Wealth & Dividend Tracking Engine",
    description="Production-grade backend engine for tracking financial, real estate, physical metals, and health assets",
    version="1.0.0",
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


@app.get("/")
async def root():
    return {
        "status": "online",
        "message": "Wealth & Dividend Tracking Engine is active.",
    }


