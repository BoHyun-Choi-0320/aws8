from flask import Flask, request, jsonify

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

reviews = {
    1: ["Great book!"],
    2: ["Very useful."]
}

@app.route('/reviews/<int:book_id>', methods=['GET'])
def get_reviews(book_id):
    return jsonify(reviews.get(book_id, []))

@app.route('/reviews/<int:book_id>', methods=['POST'])
def add_review(book_id):
    try:
        content = request.json.get("review", "")
        if content:
            reviews.setdefault(book_id, []).append(content)
            return jsonify({"status": "ok"}), 201
        else:
            return jsonify({"error": "Empty review"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)