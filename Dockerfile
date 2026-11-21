FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    NEONCLIPPING_PORT=8770 \
    NEONCLIPPING_HOST=0.0.0.0 \
    NEONCLIPPING_DOCKER=1 \
    OLLAMA_HOST=http://ollama:11434

# Install FFmpeg with full libass subtitle support, fonts, git, and curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libass-dev \
    fonts-liberation \
    fonts-dejavu-core \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install packages
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir "av<19" && \
    pip install --no-cache-dir -r requirements.txt

# Pre-download the Whisper speech model inside the Docker image (fully self-contained)
RUN python -c "from faster_whisper import download_model; download_model('large-v3-turbo')"

# Copy all application code
COPY . .

# Ensure data directory exists
RUN mkdir -p /app/data

EXPOSE 8770

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8770/healthz || exit 1

CMD ["python", "app.py"]
