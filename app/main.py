import time
import logging
from flask import Flask, jsonify, request
from pythonjsonlogger import json
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

logger = logging.getLogger("cloudlogix-api")
logHandler = logging.StreamHandler()
formatter = json.JsonFormatter('%(timestamp)s %(levelname)s %(name)s %(message)s')
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

app = Flask(__name__)

#prometheus
REQUEST_COUNT = Counter(
    'http_requests', 
    'Total HTTP Requests', 
    ['method', 'endpoint', 'status_code']
)
REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency in seconds',
    ['endpoint']
)

#metrics + logs
@app.before_request
def start_timer():
    request._start_time = time.time()

@app.after_request
def record_metrics(response):
    if hasattr(request, '_start_time'):
        latency = time.time() - request._start_time
        REQUEST_LATENCY.labels(endpoint=request.path).observe(latency)
        
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.path,
        status_code=response.status_code
    ).inc()
    
    logger.info(
        "Request processed",
        extra={
            "method": request.method,
            "path": request.path,
            "status": response.status_code,
            "ip": request.remote_addr
        }
    )
    return response

#probes

@app.route('/healthz/liveness')
def liveness():
    return jsonify({"status":"UP"}), 200

@app.route('/healthz/readiness')
def readiness():
    return jsonify({"status":"READY"}), 200

#prometheus metrics
@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

#core
@app.route('/')
def root():
    return jsonify({
        "service": "CloudLogix-API",
        "version": "1.0.0",
        "status": "Operational"
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)


