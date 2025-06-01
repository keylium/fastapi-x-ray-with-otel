FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN opentelemetry-bootstrap -a install

COPY app/ .

EXPOSE 8000

ENV OTEL_SERVICE_NAME=fastapi-xray-demo
ENV OTEL_TRACES_EXPORTER=otlp
ENV OTEL_METRICS_EXPORTER=none
ENV OTEL_LOGS_EXPORTER=none
ENV OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
ENV OTEL_EXPORTER_OTLP_PROTOCOL=grpc
ENV OTEL_RESOURCE_ATTRIBUTES=service.name=fastapi-xray-demo,service.version=1.0.0

CMD ["opentelemetry-instrument", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
