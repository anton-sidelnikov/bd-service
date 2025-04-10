"""DynamoDB operations"""

import os

import boto3

from model import DynamoResponse, User


class DynamoDBStorage:
    """DynamoDB session class"""

    def __init__(self, table_name: str):
        self.boto3_session = boto3.Session(
            region_name=os.getenv("AWS_REGION", "us-east-1")
        )
        self.table_name = table_name
        self.user = (self.boto3_session.resource("dynamodb").
                     Table(self.table_name))

    def get_user(self, username: str) -> User:
        """Get user from table"""
        item = (self.user.get_item(Key={"username": username}).get("Item"))
        return User(**item) if item else None

    def set_user(self, username: str, date_of_birth: str) -> DynamoResponse:
        """Put user into table"""
        item = self.user.put_item(  # type: ignore
            Item={"username": username, "dateOfBirth": date_of_birth}
        )
        return DynamoResponse(**item) if item else None
