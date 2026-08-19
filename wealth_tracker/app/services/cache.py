import redis.asyncio as redis
import os
import logging
import json

logger = logging.getLogger(__name__)

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

class CacheService:
    def __init__(self):
        self.redis_client = None

    async def connect(self):
        self.redis_client = redis.from_url(REDIS_URL, decode_responses=True)
        logger.info(f"Connected to Redis at {REDIS_URL}")

    async def disconnect(self):
        if self.redis_client:
            await self.redis_client.close()
            logger.info("Redis connection closed")

    async def get(self, key: str):
        if not self.redis_client:
            return None
        try:
            val = await self.redis_client.get(key)
            return json.loads(val) if val else None
        except Exception as e:
            logger.error(f"Redis GET error: {e}")
            return None

    async def set(self, key: str, value: dict, expire: int = 3600):
        if not self.redis_client:
            return
        try:
            await self.redis_client.set(key, json.dumps(value), ex=expire)
        except Exception as e:
            logger.error(f"Redis SET error: {e}")

cache_service = CacheService()
