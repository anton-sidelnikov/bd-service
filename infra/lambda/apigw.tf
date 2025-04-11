# API Gateway HTTP API
resource "aws_apigatewayv2_api" "api" {
  name          = "birthday-api-${terraform.workspace}"
  protocol_type = "HTTP"

  tags = {
    Environment = terraform.workspace
    Project     = "birthday-service"
  }
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.birthday.arn
  qualifier     = aws_lambda_alias.alias[0].name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_alias.alias[0].invoke_arn
  payload_format_version = "2.0"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /hello/{username}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Environment = terraform.workspace
    Project     = "birthday-service"
  }
}
