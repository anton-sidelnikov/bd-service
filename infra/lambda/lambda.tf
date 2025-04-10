# Function and auto-publish new version
resource "aws_lambda_function" "birthday" {
  function_name = "birthday_service"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  filename      = var.lambda_package
  source_code_hash = filebase64sha256(var.lambda_package)

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users.name
    }
  }

  publish = true
}

# Alias for prod
resource "aws_lambda_alias" "prod" {
  name             = "prod"
  function_name    = aws_lambda_function.birthday.function_name
  function_version = aws_lambda_function.birthday.version
  description      = "Production alias"
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.birthday.function_name}"
  retention_in_days = 3

  tags = {
    Name        = "Birthday Lambda Logs"
    Environment = "prod"
  }
}
