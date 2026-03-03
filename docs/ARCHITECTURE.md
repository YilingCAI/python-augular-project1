# Architecture

System architecture for application runtime, infrastructure, and delivery flow.

## Runtime topology

```text
Internet
  -> ALB (public)
  -> ECS Fargate services (private subnets)
      - backend (FastAPI)
      - frontend (Nginx + Angular)
  -> RDS PostgreSQL (db subnets)

Supporting services:
  - AWS Secrets Manager (runtime secrets)
  - Amazon ECR (container images)
  - S3 backend state + lockfile locking (Terraform)
  - CloudWatch Logs
```

## Application layers

Backend (`backend/app`):

- `api/`: route handlers
- `services/`: business logic
- `db/`: SQLAlchemy engine/session
- `models/` + `schemas/`: persistence and API contracts

Frontend (`frontend/src/app`):

- `components/`: UI features
- `services/`: API/auth/game/user clients
- `core/`: route guards and HTTP interceptor

## CI/CD flow

```text
feature/* -> PR -> develop/main

CI (`ci.yml`)
  - lint/test/security/dependency checks
  - terraform fmt/validate/plan

Staging CD (`staging.yml`)
  - triggered by successful CI on develop (or manual)
  - build/push backend+frontend images to ECR
  - terraform apply (staging)
  - ECS force deployment
  - smoke test

Release + Production CD (`release.yml`)
  - successful CI on main -> semantic-release
  - release tag `v*` -> production deploy flow
  - build/push images to ECR
  - terraform apply (production)
  - ECS force deployment
  - smoke test
```

## Secrets and configuration model

- Runtime app secrets: AWS Secrets Manager
- CI/CD orchestration secrets: GitHub repository/environment secrets
- Non-secret pipeline config: environment files under `config/`

No static AWS credentials are stored in repository files. GitHub Actions uses OIDC to assume AWS roles.

## Terraform backend model

Terraform remote state is stored in S3 and uses `use_lockfile=true` for locking.

Example init:

```bash
terraform init \
  -backend-config="bucket=<state-bucket>" \
  -backend-config="key=staging/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="use_lockfile=true"
```
