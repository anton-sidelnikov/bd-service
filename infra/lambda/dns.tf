# Only create the certificate if dns_name is provided
resource "aws_acm_certificate" "api_cert" {
  count               = var.dns_name != "" ? 1 : 0
  domain_name         = var.dns_name
  validation_method   = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation record
resource "aws_route53_record" "cert_validation" {
  count   = var.dns_name != "" ? length(aws_acm_certificate.api_cert[0].domain_validation_options) : 0

  name    = aws_acm_certificate.api_cert[0].domain_validation_options[count.index].resource_record_name
  type    = aws_acm_certificate.api_cert[0].domain_validation_options[count.index].resource_record_type
  zone_id = data.aws_route53_zone.primary.zone_id
  records = [aws_acm_certificate.api_cert[0].domain_validation_options[count.index].resource_record_value]
  ttl     = 60
}

# Confirm cert validation
resource "aws_acm_certificate_validation" "api_cert_validation" {
  count                   = var.dns_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.api_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# API Gateway custom domain
resource "aws_apigatewayv2_domain_name" "custom" {
  count                       = var.dns_name != "" ? 1 : 0
  domain_name                 = var.dns_name
  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_cert_validation[0].certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# API mapping to custom domain
resource "aws_apigatewayv2_api_mapping" "mapping" {
  count       = var.dns_name != "" ? 1 : 0
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.custom[0].id
  stage       = aws_apigatewayv2_stage.default.name
}

# DNS record pointing to API Gateway custom domain
resource "aws_route53_record" "api_alias" {
  count   = var.dns_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.primary[0].zone_id
  name    = var.dns_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.custom[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.custom[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Hosted zone lookup
locals {
  dns_parts     = split(".", var.dns_name)
  dns_zone_name = length(local.dns_parts) >= 2 ? join(".", slice(local.dns_parts, length(local.dns_parts) - 2, length(local.dns_parts))) : var.dns_name
}

data "aws_route53_zone" "primary" {
  count        = var.dns_name != "" ? 1 : 0
  name         = local.dns_zone_name
  private_zone = false
}
