# Multi-stage build: deps stage for dependency compilation
FROM --platform=linux/amd64 python:3.11-slim AS deps

WORKDIR /app

# Install uv and system dependencies for compilation
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && /root/.local/bin/uv --version

# Add uv to PATH
ENV PATH="/root/.local/bin:$PATH"

# Copy source requirements and compile dependencies
COPY app/requirements.txt .

# Use uv to compile dependencies into a locked requirements file
RUN uv pip compile requirements.txt --output-file requirements-compiled.txt

# Install base requirements first to get opentelemetry-bootstrap command
RUN uv pip install --system --no-cache -r requirements-compiled.txt

# Generate OpenTelemetry auto-instrumentation requirements
RUN opentelemetry-bootstrap -a requirements > otel-requirements.txt

# Production stage
FROM --platform=linux/amd64 python:3.11-slim AS prod

WORKDIR /app

# Install only runtime dependencies (no build tools needed)
RUN apt-get update && apt-get install -y \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled requirements from deps stage
COPY --from=deps /app/requirements-compiled.txt .
COPY --from=deps /app/otel-requirements.txt .

# Install dependencies using pip (faster, no compilation needed)
RUN pip install --no-cache-dir -r requirements-compiled.txt
RUN pip install --no-cache-dir -r otel-requirements.txt

# Copy application code
COPY app/ .

EXPOSE 8000

# OpenTelemetry configuration
ENV OTEL_SERVICE_NAME=fastapi-xray-demo
ENV OTEL_TRACES_EXPORTER=otlp
ENV OTEL_METRICS_EXPORTER=none
ENV OTEL_LOGS_EXPORTER=none
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
ENV OTEL_EXPORTER_OTLP_PROTOCOL=grpc
ENV OTEL_RESOURCE_ATTRIBUTES=service.name=fastapi-xray-demo,service.version=1.0.0

# Use opentelemetry-instrument for auto-instrumentation
CMD ["opentelemetry-instrument", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
