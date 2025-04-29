from flask import Flask, request, render_template_string, redirect
import requests

# OpenTelemetry 관련
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger.thrift import JaegerExporter

# Jaeger 설정
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

jaeger_exporter = JaegerExporter(
    agent_host_name="jaeger",  # docker-compose 사용 시 보통 서비스 이름을 사용
    agent_port=6831,
)
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

TEMPLATE = """
<h1>Book List</h1>
<ul>
{% for book in books %}
  <li>
    <strong>{{book['title']}}</strong><br/>
    <form method="post" action="/review/{{book['id']}}">
      <input name="review" placeholder="Write a review"/>
      <button type="submit">Submit</button>
    </form>
    <ul>
    {% for r in reviews.get(book['id'], []) %}
      <li>{{r}}</li>
    {% endfor %}
    </ul>
  </li>
{% endfor %}
</ul>
"""

@app.before_request
def before_request():
    # 들어온 reqq-id 저장
    reqq_id = request.headers.get('reqq-id')
    if reqq_id:
        g.reqq_id = reqq_id
        print(f"Received reqq-id : {reqq_id}")

def make_outbound_request(url, method="GET", data=None):
    headers = {}
    if hasattr(g, 'reqq_id'):
        headers['reqq-id'] = g.reqq_id

    if method == "GET":
        response = requests.get(url, headers=headers)
    elif method == "POST":
        response = requests.post(url, json=data, headers=headers)
    return response

@app.route('/')
def index():
    try:
        books = requests.get("http://book-service:5001/books").json()
    except Exception as e:
        print("Error fetching books:", e)
        books = []

    reviews = {}
    for book in books:
        try:
            r = requests.get(f"http://review-service:5002/reviews/{book['id']}").json()
        except Exception as e:
            print("Error fetching reviews for book", book['id'], ":", e)
            r = []
        reviews[book["id"]] = r

    return render_template_string(TEMPLATE, books=books, reviews=reviews)

@app.route('/review/<int:book_id>', methods=['POST'])
def add_review(book_id):
    review = request.form['review']
    try:
        requests.post(f"http://review-service:5002/reviews/{book_id}", json={"review": review})
    except Exception as e:
        print("Error posting review:", e)
    return redirect('/')

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)