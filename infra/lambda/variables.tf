variable "dynamodb_table_name" {
  description = "DynamoDB table name for lambda"
  default = "Users"
}

variable "lambda_package" {
  description = "Path to zipped Lambda function"
  default     = "../../build/lambda.zip"
}

variable "aws_region" {
  description = "AWS default region to deploy resources"
}

variable "dns_name" {
  description = "Custom domain name to assign to API (e.g. api.example.com). Leave blank to skip custom DNS."
  default     = ""
}

variable "rollback_version" {
  description = "Manual rollback version override"
  type        = string
  default     = ""
}

variable "promote" {
  description = "Whether to assign alias to the new version"
  type        = bool
  default     = false
}
