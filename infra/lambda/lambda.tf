# Function and auto-publish new version
resource "aws_lambda_function" "birthday" {
  function_name    = "birthday_service-${terraform.workspace}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = var.lambda_package
  source_code_hash = filebase64sha256(var.lambda_package)
  timeout          = 5
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users.name
    }
  }

  publish = true

  tags = {
    Environment = terraform.workspace
    Project     = "birthday-service"
  }
}

# Alias for prod
resource "aws_lambda_alias" "alias" {
  name             = terraform.workspace == "prod" ? "prod" : terraform.workspace
  function_name    = aws_lambda_function.birthday.function_name
  function_version = aws_lambda_function.birthday.version
  description      = "Production alias"

  tags = {
    Environment = terraform.workspace
    Project     = "birthday-service"
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.birthday.function_name}-${terraform.workspace}"
  retention_in_days = 3

  tags = {
    Environment = terraform.workspace
    Project     = "birthday-service"
  }
}
