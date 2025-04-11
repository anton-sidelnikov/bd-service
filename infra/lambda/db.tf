# DynamoDB Table
resource "aws_dynamodb_table" "users" {
  name         = "${terraform.workspace}-${var.dynamodb_table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"

  attribute {
    name = "username"
    type = "S"
  }
}
