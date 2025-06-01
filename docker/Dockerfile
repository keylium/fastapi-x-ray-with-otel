FROM --platform=linux/amd64 python:3.11-slim

WORKDIR /app

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

COPY app/requirements.txt .
RUN /root/.local/bin/uv pip install --system --no-cache -r requirements.txt

RUN /root/.local/bin/uv run opentelemetry-bootstrap -a requirements | /root/.local/bin/uv pip install --system --requirement -

COPY app/ .

EXPOSE 8000

ENV OTEL_SERVICE_NAME=fastapi-xray-demo
ENV OTEL_TRACES_EXPORTER=otlp
ENV OTEL_METRICS_EXPORTER=none
ENV OTEL_LOGS_EXPORTER=none
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
ENV OTEL_EXPORTER_OTLP_PROTOCOL=grpc
ENV OTEL_RESOURCE_ATTRIBUTES=service.name=fastapi-xray-demo,service.version=1.0.0

CMD ["/root/.local/bin/uv", "run", "opentelemetry-instrument", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
