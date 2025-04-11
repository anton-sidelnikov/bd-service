output "service_url" {
  value       = var.dns_name != "" ? "https://${var.dns_name}/hello/{username}" : aws_apigatewayv2_api.api.api_endpoint
  description = "Public URL for the Birthday service"
}

output "lambda_log_group" {
  value = aws_cloudwatch_log_group.lambda_logs.name
  description = "Lambda Log Group name"
}
