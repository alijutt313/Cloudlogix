import pytest
from app.main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_root_endpoint(client):
    response = client.get('/')
    assert response.status_code == 200
    assert response.json["service"] == "CloudLogix-API"

def test_liveness_endpoint(client):
    response = client.get('/healthz/liveness')
    assert response.status_code == 200
    assert response.json["status"] == "UP"

def test_metrics_endpoint(client):
    client.get('/')
    
    response = client.get('/metrics')
    assert response.status_code == 200
    assert b"http_requests_total" in response.data