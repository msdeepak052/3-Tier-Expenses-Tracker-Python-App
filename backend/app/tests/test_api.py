from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_add_and_list():
    resp = client.post("/expenses/", json={"category": "Food", "amount": 10.0})
    assert resp.status_code == 200
    data = resp.json()
    assert data["category"] == "Food"
    resp2 = client.get("/expenses/")
    assert resp2.status_code == 200
    assert any(e["id"] == data["id"] for e in resp2.json())