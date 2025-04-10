import json
from datetime import datetime, timedelta
from unittest.mock import patch

from handler import lambda_handler
from model import User


def get_event(http_method, username, body=None):
    return {
        "httpMethod": http_method,
        "pathParameters": {"username": username},
        "body": json.dumps(body) if body else None,
    }


@patch("handler.storage")
def test_put_user_success(mock_storage):
    event = get_event("PUT", "Alice", {"dateOfBirth": "1990-06-01"})
    mock_storage.set_user.return_value = None
    response = lambda_handler(event, {})
    assert response["statusCode"] == 204
    mock_storage.set_user.assert_called_once()


@patch("handler.storage")
def test_put_user_failed(mock_storage):
    event = get_event("PUT", "Alice", "")
    mock_storage.set_user.return_value = None
    response = lambda_handler(event, {})
    assert response["statusCode"] == 400
    assert "Invalid JSON input" in response["body"]
    mock_storage.set_user.assert_not_called()


@patch("handler.storage")
def test_get_user_today_birthday(mock_storage):
    today = datetime.now().strftime("%Y-%m-%d")
    mock_storage.get_user.return_value = User(
        username="alice", dateOfBirth=today
    )

    event = get_event("GET", "alice")
    response = lambda_handler(event, {})
    body = json.loads(response["body"])
    assert response["statusCode"] == 200
    assert "Happy birthday" in body["message"]


@patch("handler.storage")
def test_get_user_future_birthday(mock_storage):
    tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
    mock_storage.get_user.return_value = User(
        username="alice", dateOfBirth=tomorrow
    )

    event = get_event("GET", "alice")
    response = lambda_handler(event, {})
    body = json.loads(response["body"])
    assert response["statusCode"] == 200
    assert "in 1 day" in body["message"]
