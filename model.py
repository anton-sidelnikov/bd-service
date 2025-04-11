"""DB model description"""

from pydantic import BaseModel


class DynamoMetaData(BaseModel):
    """DynamoDB response Metadata"""

    HTTPStatusCode: int
    RequestId: str


class DynamoResponse(BaseModel):
    """DynamoDB response"""

    ResponseMetadata: DynamoMetaData


class User(BaseModel):
    """DynamoDB User table"""

    username: str
    dateOfBirth: str
