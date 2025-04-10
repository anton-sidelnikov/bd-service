provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "github_deploy" {
  name = "github-oidc-terraform-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "deploy_policy" {
  name        = "terraform-deploy-policy"
  description = "Least-privilege IAM policy for GitHub Actions Terraform deploy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # Lambda Management
      {
        Effect = "Allow",
        Action = [
          "lambda:*",
        ],
        Resource = "*"
      },

      # API Gateway V2
      {
        Effect = "Allow",
        Action = [
          "apigatewayv2:*",
        ],
        Resource = "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "apigateway:GET",
          "apigateway:POST",
          "apigateway:DELETE",
          "apigateway:PUT",
        ],
        "Resource": "arn:aws:apigateway:*"
      },

      # DynamoDB
      {
        Effect = "Allow",
        Action = [
          "dynamodb:*",
        ],
        Resource = "*"
      },

      # PassRole (for Lambda execution role only!)
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:DeleteRole",
          "iam:GetRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRolePolicy"
        ],
        Resource = "arn:aws:iam::${var.aws_account_id}:role/lambda_exec_role"
      },

      # IAM for execution role
      {
        Effect = "Allow",
        Action = [
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:GetRole",
          "iam:ListEntitiesForPolicy"
        ],
        Resource = "*"
      },

      # CloudWatch Logs (for Lambda)
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:TagResource",
          "logs:PutRetentionPolicy",
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
          "logs:DeleteLogGroup"
        ],
        Resource = "*"
      },

      # S3 Terraform State
      {
        Effect = "Allow",
        Action = [
          "s3:*",
        ],
        Resource = [
          "arn:aws:s3:::bds-tf-state",
          "arn:aws:s3:::bds-tf-state/*"
        ]
      },

      # DynamoDB State Locking
      {
        Effect = "Allow",
        Action = [
          "dynamodb:*",
        ],
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/terraform-locks"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_github_policy" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = aws_iam_policy.deploy_policy.arn
}
