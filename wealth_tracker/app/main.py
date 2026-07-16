from fastapi import FastAPI

from app.routers import holdings

app = FastAPI(
    title="Wealth & Dividend Tracking Engine",
    description="Production-grade backend engine for tracking financial and physical assets",
    version="1.0.0",
)

# Register routers
app.include_router(holdings.router)


@app.get("/")
async def root():
    return {
        "status": "online",
        "message": "Wealth & Dividend Tracking Engine is active.",
    }
