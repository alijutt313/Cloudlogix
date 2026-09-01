# Stage 1: Build dependencies
FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Minimal runtime image
FROM python:3.12-slim

WORKDIR /app

# Non-root security practice
RUN useradd -m -u 1000 appuser

COPY --from=builder /install /usr/local
COPY app/ /app/app/

USER appuser

EXPOSE 5000

ENV PYTHONUNBUFFERED=1

CMD ["python", "app/main.py"]