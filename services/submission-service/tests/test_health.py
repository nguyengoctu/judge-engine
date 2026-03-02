from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "UP"
    assert data["service"] == "submission-service"


def test_openapi_docs_available():
    response = client.get("/openapi.json")
    assert response.status_code == 200
    data = response.json()
    assert data["info"]["title"] == "Submission Service API"


@patch("app.routes.submissions.publish_submission")
@patch("app.routes.submissions.get_db")
def test_create_submission(mock_db, mock_publish):
    """POST /api/submissions should save and publish."""
    mock_session = MagicMock()
    mock_db.return_value = iter([mock_session])

    response = client.post("/api/submissions", json={
        "code": "print('hello')",
        "language": "python",
    })

    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "pending"
    assert "id" in data
