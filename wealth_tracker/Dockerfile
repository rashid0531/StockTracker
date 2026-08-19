FROM python:3.11-slim

WORKDIR /app

# Install system dependencies (for building some python packages if needed)
RUN apt-get update && apt-get install -y gcc libpq-dev && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Upgrade pip and install requirements
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir alembic redis apscheduler pyjwt "passlib[bcrypt]" python-multipart structlog

COPY . .

# Expose FastAPI port
EXPOSE 8000

# Run alembic upgrade head before starting uvicorn
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
