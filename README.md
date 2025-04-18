# Birthday Service — Infrastructure & Deployment Docs

---

## Problem Statement

Create a highly available, cost-effective, birthday notification service.

## Solutions comparison

See [Comparison document](COMPARISON.md).

### Functional Requirements

- **PUT /hello/{username}**: Saves or updates a user’s birthday.
- **GET /hello/{username}**: Responds with:
    - `Happy birthday` if it’s today
    - Countdown to birthday if it in the future

### Validation Rules

- `username` must contain only **letters**
- `dateOfBirth` must be **in the past** and formatted as `YYYY-MM-DD`

---

## Infrastructure Design

### AWS Services Used

| Service                        | Purpose                                |
|--------------------------------|----------------------------------------|
| **Lambda**                     | Hosts application logic                |
| **Cloudwatch Logs**            | Lambda logs storage                    |
| **API Gateway v2**             | HTTP endpoint + Lambda integration     |
| **DynamoDB (Users)**           | Stores user `username` + `dateOfBirth` |
| **S3**                         | Stores Terraform state                 |
| **DynamoDB (terraform-locks)** | Terraform state locking                |
| **Route 53 + ACM**             | Optional HTTPS custom domain support   |

### Architecture

Main:
```text
[User]
   |
   v
API Gateway (HTTP API)
   |
   v
Lambda function -> CloudWatch
   |
   v
DynamoDB
```

Optional:
```text
Route 53 (apiexample.com)
|
v
API Gateway Custom Domain
```

### Project Structure

```text
infra/
├── oidc/              # GitHub OIDC IAM Role + deploy policy
├── bootstrap/         # Terraform backend (S3 + DynamoDB locking)
├── lambda/            # Main infrastructure: Lambda, API, DNS, etc.
tests/                 # lambda tests
├── functional/
├── unit/
handler.py             # lambda code
model.py               # storage model types
storage.py             # storage class / DynamoDB connector
utils.py               # utility functions
requirements.txt
```

## Setup Instructions 

### GitHub

#### Step 1: GitHub OIDC Provider (Only Manual)
First need to install aws cli tool.

```bash
aws iam create-open-id-connect-provider \
--url https://token.actions.githubusercontent.com \
--client-id-list sts.amazonaws.com \
--thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```
Run once per AWS account. Required for GitHub Actions authentication.

#### Step 2: Deploy OIDC IAM Role & Policy (Only Manual)

```bash
cd infra/oidc
terraform init
terraform apply -var aws_region="eu-central-1" -var aws_account_id=1234567890
```
- Creates:
  +	IAM role: github-oidc-terraform-deploy
  +	Deploy policy: scoped to only needed AWS services

#### Step 3: Bootstrap Remote State (CI/CD common.yaml)

```bash
cd infra/bootstrap
terraform init
terraform apply -var aws_region="eu-central-1"
```
- Creates:
  +	S3 bucket for Terraform state
  +	DynamoDB lock table

#### Step 4: Deploy App Infrastructure (CI/CD deploy.yaml)

```bash
cd infra/lambda
terraform init -reconfigure
terraform apply -var aws_region="eu-central-1" -var dns_name="example.com"
```
If dns_name is blank, skips custom DNS setup.

### Local

#### Step 1: Configure AWS Credentials and Config

Files must be placed in `.aws` folder

**credentials**
```text
[default]
aws_access_key_id=AKIATWIUNHMTHBEXAMPLE
aws_secret_access_key=D0BXE8yV6Zj!A0uFzW3VyxhrVLGtjW82EXAMPLE
```
**config**
```text
[default]
region=eu-central-1
output=json
```

#### Step 2: Bootstrap Remote State (One-time)

```bash
cd infra/bootstrap
terraform init
terraform apply -var aws_region="eu-central-1"
```

- Creates:
  +	S3 bucket for Terraform state
  +	DynamoDB lock table

#### Step 3: Create Package for Lambda function

Example:
```bash
cp *.py build/
cp requirements.txt build/
cd build
pip install -r requirements.txt -t .
zip -r lambda.zip .
```

#### Step 4: Deploy App Infrastructure (Lambda + API, etc.)

```bash
cd infra/lambda
terraform init -reconfigure
terraform apply -var aws_region="eu-central-1" -var dns_name="example.com" -var promote="true" -var lambda_package="path/lambda.zip"
```
If dns_name is blank, skips custom DNS setup.

### Networking & Security

App & DB Segregation
  *	Lambda is public, but isolated and optionally VPC-enabled (not our case)
  *	DynamoDB is IAM-secured, not exposed via network
  * API Gateway is HTTPS-only (optionally custom domain)

### IAM Hardening (CI/CD)

 * Uses GitHub OIDC with short-lived auth tokens
 * Terraform deploy role has least-privilege access
 * No long-term AWS credentials required

### GitHub Hardening (CI/CD)

  * Actions: Require approval for all external contributors
  * Branch protection rules: Require a pull request before merging
  * Branch protection rules: Require approvals - 1

### DynamoDB Backup Strategy

DynamoDB does not include backups by default.

⚠️ ~> Note: backup incurs cost. Not enabled by default.

### CI/CD & Automation
 * GitHub Actions deploys infra via terraform apply
 * Lambda packaged automatically
 * Integrated with OIDC-authenticated deploy role

### Deployment Strategy

#### On Pull Request:
  
 * Creates full infrastructure in separate **pr-#** workspace
 * Assigns **pr-#.domain.name** record if **domain_name** provided
 * Deletes **pr-#** workspace and whole test infrastructure after **merge**

#### On Release:

 * Creates full infrastructure in **prod** workspace
 * Assigns **prod.domain.name** record if **domain_name** provided
 * Lambda uses published versions + prod alias only after **healthcheck** passed
 * Zero downtime deploys via alias switching


#### Additional production "manual" run workflows:
 * `destroy-prod` to complete destroy of **prod** environment
 * `rollback` by re-pointing alias to previous or input version

### Optional Enhancements/Features (ideas)

| Feature                                          | Pros                                     |
|--------------------------------------------------|------------------------------------------|
| **CloudWatch Alarms**                            | Alert on Lambda/API errors               |
| **WAF + API Gateway for IP-based rate limiting** | Prevent abuse                            |
| **DynamoDB Backup Strategy**                     | Data availability and durability         |
