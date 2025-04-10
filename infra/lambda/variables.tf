variable "dynamodb_table_name" {
  default = "Users"
}

variable "lambda_package" {
  description = "Path to zipped Lambda function"
  default     = "../../lambda.zip"
}

variable "aws_region" {}
