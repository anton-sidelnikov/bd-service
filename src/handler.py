import json
import os
from datetime import datetime

from src.model import User
from src.storage import DynamoDBStorage
from src.utils import days_until_next_birthday, is_valid_dob, is_valid_username

TABLE_NAME = os.environ.get("TABLE_NAME", "Users")
storage = DynamoDBStorage(TABLE_NAME)


def respond(status_code: int, message):
    body = message if isinstance(message, str) else json.dumps(message)
    return {
        "statusCode": status_code,
        "body": body,
        "headers": {"Content-Type": "application/json"},
    }


def lambda_handler(event, context):
    http_method = event.get("httpMethod")
    path_params = event.get("pathParameters") or {}
    username = path_params.get("username", "").strip()

    if not is_valid_username(username):
        return respond(400, "Username must contain only letters.")

    if http_method == "PUT":
        try:
            body = json.loads(event.get("body", "{}"))
            date_of_birth = body["dateOfBirth"]
        except Exception as ex:
            return respond(400, f"Invalid JSON input. Error: {ex}")

        if not is_valid_dob(date_of_birth):
            return respond(
                400, "Invalid or future date of birth. Must be in YYYY-MM-DD format"
            )

        storage.set_user(username, date_of_birth)
        return {"statusCode": 204, "body": ""}

    elif http_method == "GET":
        user: User = storage.get_user(username)
        if not user:
            return respond(404, "User not found.")

        dob = datetime.strptime(user.dateOfBirth, "%Y-%m-%d").date()
        days = days_until_next_birthday(dob)

        if days == 0:
            msg = f"Hello, {username}! Happy birthday!"
        else:
            msg = f"Hello, {username}! Your birthday is in {days} day(s)"

        return respond(200, {"message": msg})

    else:
        return respond(405, "Method Not Allowed.")
