# Infrastructure

Terraform infrastructure for AWS networking, compute, database, and deployment prerequisites.

## Provisioned resources

- VPC + public/private/db subnets
- ALB and listeners
- ECS cluster/services for backend and frontend
- RDS PostgreSQL
- IAM roles/policies needed by workloads

## Layout

```text
infra/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── backend-config.hcl
├── envs/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── modules/
    ├── vpc/
    ├── network/
    ├── alb/
    ├── ecs/
    └── rds/
```

## Backend state model

Terraform uses S3 remote state with native lockfile locking.

`backend-config.hcl`:

```hcl
bucket       = "myproject-terraform-state"
key          = "terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
```

Manual init example:

```bash
cd infra
terraform init \
  -backend-config="bucket=myproject-terraform-state" \
  -backend-config="key=staging/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="use_lockfile=true"
```

Notes:

- `dynamodb_table` is deprecated and no longer required.
- CI composite actions still accept a lock-table input for compatibility, but lockfile locking is the active mechanism.

## First-time bootstrap (per AWS account)

1. Create S3 bucket for Terraform state (versioned + encrypted)
2. Create GitHub OIDC provider in IAM
3. Create IAM roles trusted for GitHub Environments (`staging`, `production`)
4. Create ECR repositories for backend/frontend

Recommended bootstrap path in this repo:

```bash
make bootstrap
```

This runs the dedicated stack in `infra/bootstrap`.

## Local usage

```bash
make tf-validate ENV=staging
make tf-plan ENV=staging
make tf-apply ENV=staging
```

Destroy:

```bash
make tf-destroy ENV=staging
```

Direct Terraform:

```bash
cd infra
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform plan -var-file="envs/staging.tfvars"
```

## CI/CD behavior

- `ci.yml`: fmt/validate/plan only (read-only)
- `staging.yml`: Terraform apply with staging values
- `release.yml`: Terraform apply with production values after release tag

## Environment files

- `envs/staging.tfvars`: staging sizing/capacity
- `envs/prod.tfvars`: production sizing/capacity
- `envs/dev.tfvars`: developer/shared lower-cost setup

Note for `dev`: ECS desired counts are intentionally set to `0` so first-time `terraform apply` succeeds even before ECR images are pushed. After pushing images, scale up by setting `desired_count` / `frontend_desired_count` (and `min_capacity`) above `0`.

Keep shared structure in modules and only vary environment inputs in tfvars.
