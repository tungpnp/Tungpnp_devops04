from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime

app = FastAPI(title="Python AI/Data Service")

@app.get("/metrics")
def get_metrics():
    # Sẽ tích hợp Prometheus Client sau
    return {"status": "Metrics will be exposed here"}

@app.get("/api/python/hello")
def say_hello():
    return {
        "service": "Python FastAPI (AI/Data)",
        "message": "Hello from Python Microservice!",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/health")
def health_check():
    # Dùng cho Kubernetes Liveness/Readiness Probe
    return {"status": "OK"}
