output "api_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "lambda_log_group" {
  value = aws_cloudwatch_log_group.lambda_logs.name
}
