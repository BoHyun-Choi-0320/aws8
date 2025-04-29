FROM python:3.10-slim

WORKDIR /app
COPY app.py .

RUN pip install flask requests opentelemetry-api opentelemetry-sdk opentelemetry-instrumentation-flask opentelemetry-instrumentation-requests opentelemetry-exporter-jaeger

EXPOSE 5000
CMD ["python", "app.py"]
