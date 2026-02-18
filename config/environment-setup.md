# Environment Configuration Guide

How to set up development, staging, and production environments.

## 🌍 Environment Types

### Development (Local)
- **Purpose**: Developer machines
- **Config**: `.env.local`
- **Approval**: None
- **Persistence**: Local only

### Staging
- **Purpose**: Pre-production testing
- **Config**: `infra/envs/staging.tfvars` + GitHub Secrets
- **Approval**: Optional
- **Persistence**: AWS resources (3+ days retention)

### Production
- **Purpose**: User-facing application
- **Config**: `infra/envs/prod.tfvars` + GitHub Secrets
- **Approval**: Required (manual)
- **Persistence**: AWS resources (30+ days retention)

## 📝 Development Setup

### Step 1: Copy Environment Template
```bash
cp config/.env.example .env.local
```

### Step 2: Edit Local Values
```bash
# Edit with your editor
nano .env.local

# Or set individual variables
export DATABASE_URL="postgresql://postgres:mypass@localhost:5432/myproject"
```

### Step 3: Source in Shell
```bash
# Option 1: Manual source
source .env.local

# Option 2: Automatic (add to .bashrc/.zshrc)
if [ -f "$PWD/.env.local" ]; then
    source .env.local
fi
```

### Step 4: Verify
```bash
# Check variables are loaded
echo $DATABASE_URL
echo $JWT_SECRET_KEY
```

### Step 5: Run Locally
```bash
make dev
# Or individually:
make backend
make frontend
```

## 🌐 Staging Setup

### Prerequisites
- AWS account with staging credentials
- Terraform installed
- GitHub CLI installed

### Step 1: Create Staging Variables
```bash
# Copy Terraform example
cp config/terraform.tfvars.example infra/envs/staging.tfvars

# Edit with staging values
nano infra/envs/staging.tfvars
```

### Step 2: Create GitHub Secrets
```bash
# Set AWS role for GitHub Actions
gh secret set AWS_ROLE_TO_ASSUME \
  --body "arn:aws:iam::123456789012:role/GitHubActionsRole"

# Set Terraform state bucket
gh secret set TERRAFORM_STATE_BUCKET \
  --body "myproject-tf-state-staging"

# Set Terraform lock table
gh secret set TERRAFORM_LOCK_TABLE \
  --body "terraform-locks-staging"
```

### Step 3: Create AWS Secrets Manager Secrets
```bash
# Database password
aws secretsmanager create-secret \
  --name /myproject/staging/db-password \
  --secret-string "staging-db-password-here" \
  --region us-east-1

# JWT secret
aws secretsmanager create-secret \
  --name /myproject/staging/jwt-secret \
  --secret-string "staging-jwt-secret-here" \
  --region us-east-1
```

### Step 4: Plan Infrastructure
```bash
make tf-plan ENV=staging
```

### Step 5: Apply Infrastructure
```bash
make tf-apply ENV=staging
```

### Step 6: Deploy Application
```bash
make deploy ENV=staging IMAGE_TAG=v1.0.0
```

## 🔒 Production Setup

### Prerequisites
- **CRITICAL**: All team approval processes in place
- Production AWS account
- Production GitHub Secrets
- Backup and disaster recovery plan verified

### Step 1: Create Production Variables
```bash
cp config/terraform.tfvars.example infra/envs/prod.tfvars

nano infra/envs/prod.tfvars
# Important changes:
# - db_instance_class = "db.t4g.small" (or larger)
# - ecs_desired_count = 3
# - ecs_max_capacity = 10
# - multi_az = true
# - backup_retention_days = 30
```

### Step 2: Create GitHub Secrets (Production)
```bash
# Repeat for production (with prod values)
gh secret set AWS_ROLE_TO_ASSUME \
  --body "arn:aws:iam::123456789012:role/GitHubActionsRoleProd"

gh secret set TERRAFORM_STATE_BUCKET \
  --body "myproject-tf-state-prod"

gh secret set TERRAFORM_LOCK_TABLE \
  --body "terraform-locks-prod"
```

### Step 3: Create AWS Secrets (Production)
```bash
# Production database password (strong!)
aws secretsmanager create-secret \
  --name /myproject/prod/db-password \
  --secret-string "$(openssl rand -base64 32)" \
  --region us-east-1

# Production JWT secret
aws secretsmanager create-secret \
  --name /myproject/prod/jwt-secret \
  --secret-string "$(openssl rand -base64 32)" \
  --region us-east-1
```

### Step 4: Test Deployment (Staging First!)
```bash
# Always test in staging first
make deploy ENV=staging IMAGE_TAG=v1.0.0

# Monitor logs
aws logs tail /aws/ecs/myproject-staging --follow

# Run smoke tests
# (your test suite here)

# If everything good, then:
make deploy ENV=prod IMAGE_TAG=v1.0.0
```

## 🔄 Environment-Specific Configuration

### Development
```bash
# .env.local
DEBUG=true
LOG_LEVEL=DEBUG
ENVIRONMENT=local
DATABASE_URL=postgresql://postgres:local@localhost:5432/myproject
JWT_EXPIRATION_HOURS=24
CORS_ORIGINS=["http://localhost:4200"]
```

### Staging
```bash
# infra/envs/staging.tfvars
environment = "staging"
ecs_desired_count = 2
ecs_min_capacity = 1
ecs_max_capacity = 4
db_instance_class = "db.t4g.micro"
backup_retention_days = 7
multi_az = false
```

### Production
```bash
# infra/envs/prod.tfvars
environment = "prod"
ecs_desired_count = 3
ecs_min_capacity = 2
ecs_max_capacity = 10
db_instance_class = "db.t4g.small"
backup_retention_days = 30
multi_az = true
```

## 📊 Database Configuration per Environment

### Development (Local)
- Engine: PostgreSQL 16 (local)
- Storage: 1GB
- Backup: None
- Replication: None

### Staging
- Engine: PostgreSQL 16 (AWS RDS)
- Storage: 20GB
- Backup: 7 days
- Replication: Single AZ

### Production
- Engine: PostgreSQL 16 (AWS RDS)
- Storage: 100GB+
- Backup: 30 days (incremental)
- Replication: Multi-AZ (high availability)

## 🐳 Docker Configuration per Environment

### Development
```bash
# Uses local docker-compose
make dev

# Exposes:
# - Backend: http://localhost:8000
# - Frontend: http://localhost:4200
# - Database: localhost:5432
```

### Staging/Production
```bash
# Uses ECR images
make docker-build ENV=staging IMAGE_TAG=v1.0.0
make docker-push ENV=staging

# Deployed to:
# ECS Cluster → Fargate tasks → ALB → CloudFront
```

## ✅ Pre-Deployment Checklist

### Before Staging Deployment
- [ ] All tests passing locally (`make test`)
- [ ] Code formatted (`make format`)
- [ ] No linting errors (`make lint`)
- [ ] Staging secrets created in AWS Secrets Manager
- [ ] GitHub Secrets set for staging
- [ ] Terraform plan reviewed (`make tf-plan ENV=staging`)

### Before Production Deployment
- [ ] All staging tests passing
- [ ] App running stable in staging (24+ hours)
- [ ] Production secrets created
- [ ] Approval from team lead obtained
- [ ] Backup of production database verified
- [ ] Rollback plan documented
- [ ] Monitoring and alerts configured

## 🚨 Troubleshooting

### Environment Variable Not Found
```bash
# Check if sourced
echo $DATABASE_URL

# Source manually
source .env.local

# Check .env.local exists
ls -la .env.local
```

### Different Config Between Envs
```bash
# Check which config is loaded
make tf-plan ENV=staging  # Should use staging.tfvars

# Verify path
cat infra/envs/staging.tfvars
```

### Secrets Not Injected
```bash
# Check in ECS console:
# Task Definitions → View JSON → containerDefinitions → environment

# Or via AWS CLI:
aws ecs describe-task-definition --task-definition myproject-backend:1 \
  --query 'taskDefinition.containerDefinitions[0].environment'
```

## 📚 Related Docs

- [secrets-management.md](secrets-management.md) - How secrets are handled
- [../docs/DEPLOYMENT_GUIDE.md](../docs/DEPLOYMENT_GUIDE.md) - Deployment procedures
- [../docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) - Common issues
