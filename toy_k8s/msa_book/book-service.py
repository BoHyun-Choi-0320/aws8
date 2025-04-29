from flask import Flask, jsonify

# OpenTelemetry 관련
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger.thrift import JaegerExporter

# Jaeger 설정
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

jaeger_exporter = JaegerExporter(
    agent_host_name="jaeger",
    agent_port=6831,
)
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)

@app.route('/books', methods=['GET'])
def get_books():
    books = [
        {"id": 1, "title": "Clean Code"},
        {"id": 2, "title": "The Pragmatic Programmer"},
        {"id": 3, "title": "Refactoring"},
        {"id": 4, "title": "Design Patterns"}
    ]
    return jsonify(books)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)