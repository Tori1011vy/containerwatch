from flask import Flask, Response
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
import random
import time

app = Flask(__name__)

REQUESTS = Counter(
    "containerwatch_http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)
LATENCY = Histogram(
    "containerwatch_http_request_duration_seconds",
    "HTTP request latency",
    ["endpoint"],
)
IN_PROGRESS = Gauge(
    "containerwatch_http_requests_in_progress",
    "Requests currently being processed",
)

@app.get("/")
def index():
    REQUESTS.labels("GET", "/", "200").inc()
    return {"service": "ContainerWatch sample app", "status": "running"}

@app.get("/healthz")
def health():
    return {"status": "healthy"}, 200

@app.get("/work")
def work():
    IN_PROGRESS.inc()
    started = time.time()
    try:
        delay = random.uniform(0.05, 1.0)
        time.sleep(delay)
        if random.random() < 0.05:
            REQUESTS.labels("GET", "/work", "500").inc()
            return {"status": "simulated error"}, 500
        REQUESTS.labels("GET", "/work", "200").inc()
        return {"status": "ok", "delay_seconds": round(delay, 3)}, 200
    finally:
        LATENCY.labels("/work").observe(time.time() - started)
        IN_PROGRESS.dec()

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)
