import re

with open('app/main.py', 'r') as f:
    content = f.read()

# Add admin import
content = content.replace('from app.routers import holdings', 'from app.routers import holdings, admin')

# Include admin router
content = content.replace('app.include_router(ai_suggestions.router)', 'app.include_router(ai_suggestions.router)\napp.include_router(admin.router)')

# Add lifecycle context manager
lifecycle = """from contextlib import asynccontextmanager
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
"""
# Replace old FastAPI init
old_init = """app = FastAPI(
    title="Wealth & Dividend Tracking Engine",
    description="Production-grade backend engine for tracking financial, real estate, physical metals, and health assets",
    version="1.0.0",
)"""
content = content.replace(old_init, lifecycle)

with open('app/main.py', 'w') as f:
    f.write(content)
