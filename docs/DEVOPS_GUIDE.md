# DevOps Refactoring - Make + Shell Scripts + GitHub Actions

## 📋 Overview

This document describes the refactored DevOps infrastructure using:
- **Makefile**: Developer-friendly CLI interface at project root
- **Shell Scripts**: Implementation logic for complex operations in `scripts/` folder
- **GitHub Actions**: CI/CD orchestration that calls Makefile targets

---

## 🏗️ Architecture

```
Developer / CI/CD
       ↓
   Makefile (make targets)
       ↓
   Shell Scripts (implementation)
       ↓
   Terraform / Docker / ECS / AWS APIs
```

### Three-Layer Approach

1. **Layer 1 - Makefile** (Developer Interface)
   - Simple, memorable targets
   - Environment validation
   - Parameter passing
   - Local execution support

2. **Layer 2 - Shell Scripts** (Implementation)
   - Complex logic (Terraform, Docker, ECS)
   - Error handling and validation
   - Colored output and logging
   - Artifact management

3. **Layer 3 - GitHub Actions** (CI/CD Orchestration)
   - Calls Makefile targets
   - Injects secrets as env vars
   - Manages job dependencies
   - Produces deployment reports

---

## 🚀 Quick Start

### Local Development

```bash
# Install dependencies
make install

# Run backend & frontend locally
make dev

# Run tests
make test
make backend-test
make frontend-test

# Format and lint code
make format
make lint
```

### Local Infrastructure Operations

```bash
# Plan infrastructure for staging
make tf-plan ENV=staging

# Apply infrastructure for staging
make tf-apply ENV=staging

# View Terraform help
make tf-validate

# Destroy infrastructure (careful!)
make tf-destroy ENV=staging
```

### Local Docker Operations

```bash
# Build Docker images (local)
ENV=staging make docker-build

# Build and push to ECR
ENV=staging make docker-push

# Full deployment locally
make deploy ENV=staging IMAGE_TAG=my-tag
```

---

## 📝 Makefile Reference

### Local Development Targets

| Target | Purpose |
|--------|---------|
| `make help` | Show all available targets |
| `make install` | Install backend & frontend dependencies |
| `make dev` | Run backend and frontend in dev mode |
| `make backend` | Run backend only |
| `make frontend` | Run frontend only |

### Testing & Quality

| Target | Purpose |
|--------|---------|
| `make test` | Run all tests |
| `make backend-test` | Run Python pytest |
| `make frontend-test` | Run Jest tests |
| `make lint` | Run ruff, eslint |
| `make format` | Format code (black, prettier) |

### Terraform Targets

| Target | Purpose |
|--------|---------|
| `make tf-validate` | Validate Terraform (no state required) |
| `make tf-plan ENV=staging` | Plan infrastructure changes |
| `make tf-apply ENV=staging` | Apply infrastructure changes |
| `make tf-destroy ENV=staging` | Destroy infrastructure |

### Docker Targets

| Target | Purpose |
|--------|---------|
| `make docker-build ENV=staging` | Build images locally |
| `make docker-push ENV=staging` | Build and push to ECR |

### Deployment Targets

| Target | Purpose |
|--------|---------|
| `make ecs-deploy ENV=staging IMAGE_TAG=sha-abc123` | Deploy to ECS |
| `make deploy ENV=staging IMAGE_TAG=sha-abc123` | Full deployment (Docker + ECS) |
| `make deploy-staging IMAGE_TAG=sha-abc123` | Quick staging deploy |
| `make deploy-prod IMAGE_TAG=v1.2.3` | Quick prod deploy |

### Environment & Cleanup

| Target | Purpose |
|--------|---------|
| `make setup-env` | Setup environment variables |
| `make clean-env` | Remove .env files |
| `make build` | Build backend & frontend |
| `make clean` | Remove build artifacts |

---

## 🔧 Shell Scripts Reference

### scripts/setup-env.sh
**Purpose**: Configure environment variables for deployment

```bash
ENV=staging bash scripts/setup-env.sh
```

**Configures**:
- AWS region and credentials
- Terraform backend (S3 + DynamoDB)
- ECR registry paths
- ECS cluster names
- Service names

**Environment Variables Set**:
- `AWS_REGION`
- `TF_ROOT`, `TF_VAR_*`
- `TERRAFORM_STATE_BUCKET`
- `TERRAFORM_LOCK_TABLE`
- `ECR_REGISTRY`
- `ECR_REPOSITORY_BACKEND`
- `ECR_REPOSITORY_FRONTEND`
- `ECS_CLUSTER`
- `ECS_SERVICE_BACKEND`
- `ECS_SERVICE_FRONTEND`

---

### scripts/terraform-validate.sh
**Purpose**: Validate Terraform without state

```bash
make tf-validate
```

**Steps**:
1. Format check (`terraform fmt`)
2. Backend-less initialization
3. Syntax validation
4. tflint linting

---

### scripts/terraform-plan.sh
**Purpose**: Plan infrastructure changes with IaC security scanning

```bash
ENV=staging bash scripts/terraform-plan.sh
```

**Steps**:
1. Source environment variables
2. Configure S3 + DynamoDB backend
3. Initialize Terraform
4. Generate plan from `.tfvars`
5. Run Checkov IaC scanning
6. Export plan artifact

**Requires**:
- `ENV` environment variable (staging|prod)
- `envs/{ENV}.tfvars` file
- AWS credentials with S3/DynamoDB access

**Output**:
- `/tmp/tf-plans/tfplan.{ENV}` - Plan artifact
- `/tmp/tf-outputs-{ENV}.json` - Terraform outputs

---

### scripts/terraform-apply.sh
**Purpose**: Apply Terraform changes from plan

```bash
ENV=prod bash scripts/terraform-apply.sh
```

**Steps**:
1. Validate plan artifact exists
2. Confirmation for production
3. Configure backend
4. Apply terraform from plan
5. Export outputs to JSON
6. Extract key outputs (ECS cluster, ALB endpoint)

**Safety Features**:
- Manual confirmation required for prod
- Uses pre-generated plan (no inline apply)
- State locking via DynamoDB

**Output**:
- Terraform state updated in S3
- Outputs exported to `/tmp/tf-outputs-{ENV}.json`

---

### scripts/docker-build.sh
**Purpose**: Build Docker images and optionally push to ECR

```bash
# Build only
ENV=staging bash scripts/docker-build.sh

# Build and push
ENV=staging bash scripts/docker-build.sh push
```

**Steps**:
1. Authenticate to ECR (if pushing)
2. Build backend image with tags
3. Build frontend image with tags
4. Run Trivy vulnerability scanning
5. Push to ECR (if requested)

**Image Naming**:
- Backend: `{ECR_REGISTRY}/mypythonproject1/backend:{IMAGE_TAG}`
- Frontend: `{ECR_REGISTRY}/mypythonproject1/frontend:{IMAGE_TAG}`

**Build Args**:
- `BUILD_DATE`: Build timestamp
- `VCS_REF`: Git commit hash
- `VERSION`: Environment name

**Output**:
- `/tmp/backend_image_uri.txt` - Backend image URI
- `/tmp/frontend_image_uri.txt` - Frontend image URI

---

### scripts/ecs-deploy.sh
**Purpose**: Deploy to ECS Fargate with health checks

```bash
ENV=staging IMAGE_TAG=sha-abc123 bash scripts/ecs-deploy.sh
```

**Steps**:
1. Pre-deployment validation
   - Check cluster exists
   - Check services exist
2. Update backend task definition
3. Register new backend task definition
4. Update backend service
5. Update frontend task definition
6. Register new frontend task definition
7. Update frontend service
8. Wait for deployment stability
9. Verify running task counts

**Requirements**:
- `ENV` environment variable
- `IMAGE_TAG` environment variable
- Terraform outputs file (for cluster/service names)
- AWS credentials with ECS permissions

**Safety Features**:
- Pre-deployment cluster validation
- Waits for task stability
- Verifies running task counts
- Post-deployment verification

---

### scripts/terraform-destroy.sh
**Purpose**: Safely destroy infrastructure with confirmation

```bash
ENV=staging bash scripts/terraform-destroy.sh
```

**Safety**:
- Big warning message
- Requires manual confirmation
- Type-safe confirmation (`destroy {ENV}`)

**Steps**:
1. Display danger warning
2. Require user confirmation
3. Configure backend
4. Run `terraform destroy -auto-approve`
5. Update state in S3

---

## 🔄 GitHub Actions Integration

### Workflow: deploy.yml (Reusable Workflow)

**Called by**: deploy-staging.yml, deploy-prod.yml

**Inputs**:
```yaml
environment: staging|prod|dev       # Required
image-tag: docker-image-tag          # Required  
run-terraform: true|false            # Optional (default: false)
require-approval: true|false         # Optional (default: false)
terraform-only: true|false           # Optional (default: false)
```

**Secrets**:
```yaml
AWS_ROLE_TO_ASSUME                   # Required
TERRAFORM_STATE_BUCKET               # Required
TERRAFORM_LOCK_TABLE                 # Required
```

### Job Flow

```
validate (validates inputs)
    ↓
approval (if require-approval=true)
    ↓
terraform-plan (if run-terraform=true)
    ↓
terraform-apply (if run-terraform=true)
    ↓
docker-build (if !terraform-only)
    ↓
ecs-deploy (if !terraform-only)
    ↓
post-deployment (on success)
    ↓
notify-failure (on failure)
```

### Job Details

#### Job: validate
- Validates environment (dev|staging|prod)
- Validates image-tag not empty
- Sets `proceed=true` if valid

#### Job: approval
- Only runs if `require-approval=true`
- Uses GitHub environment: `{environment}-approval`
- Blocks until manual approval in GitHub UI

#### Job: terraform-plan
- Only runs if `run-terraform=true`
- Configures AWS via OIDC
- Calls `make tf-plan ENV={environment}`
- Uploads plan artifact

#### Job: terraform-apply
- Only runs if `run-terraform=true` AND plan succeeded
- Downloads plan artifact
- Calls `make tf-apply ENV={environment}`
- Exports outputs for downstream jobs

#### Job: docker-build
- Only runs if `!terraform-only`
- Gets AWS account ID
- Calls `make docker-push ENV={environment}`
- Builds and pushes to ECR

#### Job: ecs-deploy
- Waits for terraform-apply and docker-build
- Gets AWS account ID
- Calls `make ecs-deploy ENV={environment} IMAGE_TAG={image-tag}`
- Updates ECS services

#### Job: post-deployment
- Only runs on success
- Creates deployment summary in GitHub UI

#### Job: notify-failure
- Only runs on failure
- Creates failure summary in GitHub UI

---

## 🔐 Secrets Management

### GitHub Secrets Required

```
AWS_ROLE_TO_ASSUME              # IAM role for OIDC
TERRAFORM_STATE_BUCKET          # S3 bucket name
TERRAFORM_LOCK_TABLE            # DynamoDB table name
```

### Environment-Specific Secrets

Can be set via GitHub environments:
- `staging` environment
- `prod-terraform` environment (for approval gate)
- `prod` environment

---

## 📊 Environment Configuration

### .tfvars Files

Location: `infra/envs/{ENV}.tfvars`

```hcl
# infra/envs/staging.tfvars
environment       = "staging"
aws_region        = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]

# ECS Configuration
ecs_task_cpu      = "256"
ecs_task_memory   = "512"
ecs_desired_count = 1

# Database
db_engine         = "postgres"
db_version        = "15.3"
db_instance_class = "db.t3.micro"

# Secrets (can come from TF_VAR_* env vars)
# db_password     = var.db_password
# jwt_secret_key  = var.jwt_secret_key
```

### Environment Variables

Set via GitHub Actions secrets or locally:

```bash
export ENV=staging
export TERRAFORM_STATE_BUCKET=mypythonproject1-tf-state-staging
export TERRAFORM_LOCK_TABLE=terraform-locks-staging
export AWS_REGION=us-east-1
export IMAGE_TAG=sha-abc123
```

---

## 🎯 Common Workflows

### Local Development Workflow

```bash
# 1. Install dependencies
make install

# 2. Run locally
make dev

# 3. Test code
make test

# 4. Format code before commit
make format
make lint
```

### Local Infrastructure Testing

```bash
# 1. Plan staging infrastructure
make tf-plan ENV=staging

# 2. Review plan output

# 3. Apply if satisfied
make tf-apply ENV=staging

# 4. Test with Docker
ENV=staging make docker-build
```

### CI/CD Deployment (Staging)

```bash
# 1. Push to develop branch
git push origin develop

# 2. GitHub Actions automatically:
#    - Runs CI tests
#    - Plans infrastructure
#    - Builds Docker images
#    - Deploys to ECS
#    - Verifies health checks

# 3. Monitor in GitHub Actions UI
gh run list
```

### CI/CD Deployment (Production)

```bash
# 1. Merge develop → main
git checkout main
git merge develop
git push origin main

# 2. GitHub Actions:
#    - Runs CI tests
#    - Plans infrastructure
#    - WAITS FOR APPROVAL (prod-terraform environment)

# 3. Review Terraform changes and click "Approve" in GitHub UI

# 4. GitHub Actions continues:
#    - Applies Terraform
#    - Builds Docker images
#    - Deploys to ECS
#    - Creates GitHub release
```

---

## 🚨 Troubleshooting

### Local Makefile Issues

```bash
# Show all targets
make help

# See what make would do (dry run)
make -n target-name

# Run with verbose output
make -d target-name
```

### Script Debugging

```bash
# Run script with bash -x for tracing
bash -x scripts/terraform-plan.sh

# Check environment variables
bash scripts/setup-env.sh  # Shows summary

# Verify AWS credentials
aws sts get-caller-identity
```

### Terraform Issues

```bash
# Check state
aws s3 ls s3://mypythonproject1-tf-state-staging/

# Check lock table
aws dynamodb scan --table-name terraform-locks-staging

# Force unlock (use with caution)
terraform -chdir=infra force-unlock <LOCK_ID>
```

### Docker/ECR Issues

```bash
# Check ECR login
aws ecr get-login-password --region us-east-1

# List images
aws ecr describe-images --repository-name mypythonproject1/backend

# View image vulnerabilities
trivy image <ECR_REGISTRY>/mypythonproject1/backend:latest
```

### ECS Deployment Issues

```bash
# Check service status
aws ecs describe-services --cluster staging --services backend-service-staging

# View task logs
aws ecs describe-tasks --cluster staging --tasks <TASK_ARN>

# Check events
aws ecs describe-services --cluster staging --services backend-service-staging \
  --query 'services[0].events'
```

---

## 📚 File Structure

```
.
├── Makefile                          # Developer CLI interface
├── scripts/
│   ├── setup-env.sh                  # Environment configuration
│   ├── terraform-validate.sh         # Terraform validation
│   ├── terraform-plan.sh             # Infrastructure planning
│   ├── terraform-apply.sh            # Infrastructure apply
│   ├── terraform-destroy.sh          # Infrastructure destruction
│   ├── docker-build.sh               # Docker image building
│   └── ecs-deploy.sh                 # ECS deployment
├── infra/
│   ├── main.tf                       # Terraform main config
│   ├── envs/
│   │   ├── staging.tfvars
│   │   └── prod.tfvars
│   └── modules/                      # Terraform modules
├── .github/
│   └── workflows/
│       ├── ci.yml                    # CI pipeline (testing)
│       ├── deploy.yml                # Reusable deployment workflow
│       ├── deploy-staging.yml        # Staging orchestration
│       └── deploy-prod.yml           # Production orchestration
├── backend/
├── frontend/
└── docker-compose.yml                # Local dev setup
```

---

## ✨ Key Features

✅ **Reproducible**: Same commands work locally and in CI/CD  
✅ **Safe**: Plan/Apply separation prevents accidents  
✅ **Parameterized**: Environment variables for multi-env support  
✅ **Auditable**: Detailed logging and reporting  
✅ **Modular**: Reusable components (actions, scripts)  
✅ **User-Friendly**: Simple Makefile interface  
✅ **Scalable**: Easy to add new environments  
✅ **Secure**: Secrets via GitHub Actions secrets  

---

## 🔄 Next Steps

1. **Test Locally**: `make tf-plan ENV=staging`
2. **Deploy Staging**: Push to `develop` branch
3. **Verify in Prod**: Merge `develop` → `main`
4. **Monitor**: Watch GitHub Actions UI
5. **Iterate**: Feedback loop for improvements

---

**Version**: 2.1.0  
**Status**: Production Ready  
**Last Updated**: February 18, 2026
