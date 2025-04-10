# bd-service
HomeWork

Use AWS SSO credentials for GitHub Actions to authenticate and deploy Terraform via OIDC (OpenID Connect)
```bash
cd infra/oidc && terraform init && terraform apply -var aws_region="eu-central-1" - var aws_account_id=1234567890
```

OIDC Trust Policy: 
```yaml
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<account_id>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<org>/<repo>:ref:refs/heads/pull/*"
          # "token.actions.githubusercontent.com:sub": "repo:<org>/<repo>:ref:refs/heads/tags/*" later
        }
      }
    }
  ]
}
```

IAM Permissions Policy
```yaml
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaManagement",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:PublishVersion",
        "lambda:CreateAlias",
        "lambda:UpdateAlias",
        "lambda:GetFunction",
        "lambda:AddPermission",
        "lambda:ListVersionsByFunction"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ApiGateway",
      "Effect": "Allow",
      "Action": [
        "apigatewayv2:CreateApi",
        "apigatewayv2:CreateRoute",
        "apigatewayv2:CreateIntegration",
        "apigatewayv2:CreateStage",
        "apigatewayv2:DeleteApi",
        "apigatewayv2:GetApi",
        "apigatewayv2:UpdateApi",
        "apigatewayv2:UpdateStage",
        "apigatewayv2:GetIntegration",
        "apigatewayv2:TagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:TagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "iam:PassRole",
        "iam:GetRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3TerraformState",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-birthday-tf-state",
        "arn:aws:s3:::my-birthday-tf-state/*"
      ]
    },
    {
      "Sid": "DynamoLockTable",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:<account_id>:table/terraform-locks"
    }
  ]
}
```


AWS_REGION=eu-central-1 - required
TABLE_NAME - optional