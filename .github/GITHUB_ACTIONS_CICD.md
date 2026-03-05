# GitHub Actions CI/CD Guide

Reference for CI validation and deployment workflows in this repository.

## Workflows

- `ci.yml` — lint, tests, security/dependency checks, Terraform plan validation
- `staging.yml` — staging build/apply/deploy/smoke-test
- `release.yml` — semantic release and production deploy flow
- `_smoke-test.yml` — reusable post-deploy health check

## `ci.yml`

Triggers:

- `pull_request` to `main` and `develop`
- `push` to `main` and `develop`
- `workflow_dispatch`

Responsibilities:

- Conventional commit check (PR)
- Backend lint + unit/integration tests
- Frontend lint + type-check + build
- Trivy + GitGuardian scan
- Snyk dependency audit
- Terraform fmt/validate/plan (no apply)
- Final `quality-gate` status

## `staging.yml`

Triggers:

- successful `CI` workflow run on `develop`
- manual dispatch

Responsibilities:

- Build/push backend and frontend images to ECR
- Apply staging Terraform
- Force ECS rolling deploy for both services
- Run reusable smoke test against `vars.APP_URL`

Config model:

- Non-secret values loaded from `config/.env.staging`
- Secrets from GitHub Environment `staging`

## `release.yml`

Two flows:

1. Semantic release flow
   - Trigger: successful `CI` workflow run on `main` (or manual dispatch)
   - Runs semantic-release (creates version tag/release)
2. Production deploy flow
   - Trigger: tag push `v*`
   - Builds/pushes images to ECR
   - Runs Terraform apply for production
   - Forces ECS deploy
   - Runs smoke test against `vars.APP_URL`

Config model:

- Uses GitHub Environment `production` secrets

## Required GitHub configuration

### Repository secrets

- `DATABASE_USER`
- `DATABASE_PASSWORD`
- `DATABASE_NAME`
- `DATABASE_PORT`
- `AWS_ROLE_TO_ASSUME`
- `GITGUARDIAN_API_KEY`
- `SNYK_TOKEN`

### Environment `staging` secrets

- `AWS_ROLE_TO_ASSUME`
- `TERRAFORM_STATE_BUCKET`
- `TERRAFORM_LOCK_TABLE` (compatibility input)
- `JWT_SECRET_KEY`

### Environment `staging` vars

- `APP_URL`

### Environment `production` secrets

- `AWS_ROLE_TO_ASSUME`
- `AWS_REGION`
- `TF_VERSION`
- `TERRAFORM_STATE_BUCKET`
- `TERRAFORM_LOCK_TABLE` (compatibility input)
- `JWT_SECRET_KEY`

### Environment `production` vars

- `APP_URL`

## Terraform backend lock note

Infrastructure init now uses `use_lockfile=true` for backend locking.

`TERRAFORM_LOCK_TABLE` remains exposed in current workflow inputs for backward compatibility.

## Related files

- `.github/workflows/ci.yml`
- `.github/workflows/staging.yml`
- `.github/workflows/release.yml`
- `.github/workflows/_smoke-test.yml`
