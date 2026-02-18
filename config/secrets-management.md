# Secrets Management - Complete Guide

This document explains how secrets are managed across development, CI/CD, and production environments.

## 🔐 Core Principle

**Secrets never appear in code.** Instead:
- **Development**: Local `.env.local` files (gitignored)
- **CI/CD**: GitHub Secrets (encrypted)
- **Runtime**: AWS Secrets Manager (encrypted)

## Secrets Types & Where They Live

### 1. GitHub Secrets (CI/CD Pipeline)

Used by GitHub Actions workflows. Stored in repository settings.

**Required Secrets:**
```
AWS_ROLE_TO_ASSUME              # ARN of GitHubActionsRole
TERRAFORM_STATE_BUCKET          # S3 bucket for Terraform state
TERRAFORM_LOCK_TABLE            # DynamoDB table for state locking
```

**Setting Up:**
```bash
# Using GitHub CLI
gh secret set AWS_ROLE_TO_ASSUME --body "arn:aws:iam::123456789012:role/GitHubActionsRole"
gh secret set TERRAFORM_STATE_BUCKET --body "myproject-tf-state-staging"
gh secret set TERRAFORM_LOCK_TABLE --body "terraform-locks-staging"
```

**In Workflows:**
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
```

### 2. AWS Secrets Manager (Runtime)

Stores application secrets that are injected into ECS tasks.

**Secrets to Create:**
```bash
# Database password
aws secretsmanager create-secret \
  --name /myproject/staging/db-password \
  --secret-string "your-db-password" \
  --region us-east-1

# JWT secret
aws secretsmanager create-secret \
  --name /myproject/staging/jwt-secret \
  --secret-string "your-jwt-secret" \
  --region us-east-1

# API keys or third-party credentials
aws secretsmanager create-secret \
  --name /myproject/staging/api-keys \
  --secret-string '{"key1": "value1", "key2": "value2"}' \
  --region us-east-1
```

**In Terraform (variables.tf):**
```hcl
data "aws_secretsmanager_secret" "db_password" {
  name = "/myproject/${var.environment}/db-password"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)
}
```

**In ECS Task Definition (Terraform):**
```hcl
container_definitions = jsonencode([
  {
    name      = "backend"
    image     = aws_ecr_repository.backend.repository_url
    environment = [
      { name = "DATABASE_URL", value = "postgresql://postgres:${local.db_password}@${aws_db_instance.postgres.endpoint}/myproject" },
      { name = "JWT_SECRET_KEY", value = local.jwt_secret },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }
])
```

### 3. Local Development (.env.local)

For developers working locally.

**Setup:**
```bash
# Copy template
cp config/.env.example .env.local

# Edit with your local values
# NEVER commit .env.local
```

**Example .env.local:**
```env
DATABASE_URL=postgresql://postgres:mypass@localhost:5432/myproject
JWT_SECRET_KEY=local-dev-secret
AWS_ACCESS_KEY_ID=local
AWS_SECRET_ACCESS_KEY=local
```

**Usage in Backend:**
```python
import os
from dotenv import load_dotenv

load_dotenv('.env.local')

database_url = os.getenv('DATABASE_URL')
jwt_secret = os.getenv('JWT_SECRET_KEY')
```

**Usage in Frontend:**
```typescript
import { environment } from './environments/environment';

// Uses environment variables or .env.local
const apiUrl = process.env['NG_APP_API_URL'] || 'http://localhost:8000';
```

**Usage in Scripts:**
```bash
#!/bin/bash
set -a
source .env.local
set +a

# Now $DATABASE_URL and other vars are available
echo "Database: $DATABASE_URL"
```

## 🔄 Secret Flow by Environment

### Development Flow
```
Developer creates .env.local
    ↓
Runs: make dev
    ↓
Script sources .env.local
    ↓
Application reads environment variables
    ↓
Connects to local PostgreSQL with local secrets
```

### Staging/Production Flow via CI/CD
```
Developer pushes code to develop/main
    ↓
GitHub Actions triggered
    ↓
Workflow reads GitHub Secrets
    ↓
Secrets passed to script via env variables
    ↓
Script runs make tf-plan / make tf-apply
    ↓
Terraform reads secrets from AWS Secrets Manager
    ↓
Terraform injects secrets into ECS task definition
    ↓
ECS starts container with environment variables
    ↓
Application reads from environment at runtime
```

## 🛡️ Best Practices

### ✅ Do's

- ✅ Store in `.env.local` for local development
- ✅ Store in GitHub Secrets for CI/CD infrastructure
- ✅ Store in AWS Secrets Manager for runtime
- ✅ Use `export` in scripts to pass through environment
- ✅ Rotate secrets regularly (every 90 days)
- ✅ Use environment-specific secrets (dev vs prod)
- ✅ Add `.env.local` to `.gitignore` (already done)
- ✅ Log secret names (not values) for debugging
- ✅ Use AWS IAM roles instead of hardcoded credentials

### ❌ Don'ts

- ❌ Never commit `.env.local` to git
- ❌ Never hardcode secrets in code
- ❌ Never put secrets in Makefile
- ❌ Never put secrets in shell scripts
- ❌ Never put secrets in Terraform code
- ❌ Never use same secrets across environments
- ❌ Never share secrets in Slack/Email
- ❌ Never log secret values

## 🚨 Incident Response

### If a Secret is Exposed

1. **Immediately rotate the secret:**
   ```bash
   # Update in AWS Secrets Manager
   aws secretsmanager put-secret-value \
     --secret-id /myproject/staging/db-password \
     --secret-string "new-password"
   ```

2. **Update all places using it:**
   - GitHub Actions workflows (if used)
   - ECS task definitions
   - Local `.env.local` files (manually for each developer)
   - Third-party services (if applicable)

3. **Audit access:**
   ```bash
   # Check CloudWatch logs
   aws logs tail /aws/ecs/myproject --follow
   ```

4. **Document the incident:**
   - What was exposed
   - When it was discovered
   - What actions were taken
   - Timeline

## 📋 Secrets Checklist

Before deploying to production:

- [ ] All secrets in AWS Secrets Manager
- [ ] No secrets in Terraform code
- [ ] No secrets in shell scripts
- [ ] No secrets in Makefile
- [ ] All secrets follow naming convention: `/myproject/{env}/{secret-name}`
- [ ] GitHub Actions uses `${{ secrets.* }}`
- [ ] ECS task definition reads from environment
- [ ] `.env.local` added to `.gitignore`
- [ ] Team trained on secrets policy
- [ ] Secret rotation schedule established

## 🔗 Related Documentation

- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Terraform AWS Secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret)
- [ECS Task IAM Roles](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_IAM_roles.html)
