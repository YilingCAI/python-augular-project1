# Secrets Management Guide

This repository separates runtime application secrets from CI/CD orchestration secrets.

## Core rules

- Never commit secrets to git
- Keep runtime secrets in AWS Secrets Manager
- Keep CI/CD orchestration secrets in GitHub Secrets (repo/environment)
- Keep only non-secret configuration in `config/.env.*`

## Secret locations by scope

### GitHub Secrets (CI/CD)

Repository-level (used by `ci.yml`):

- `DATABASE_USER`
- `DATABASE_PASSWORD`
- `DATABASE_NAME`
- `DATABASE_PORT`
- `AWS_ROLE_TO_ASSUME`
- `GITGUARDIAN_API_KEY`
- `SNYK_TOKEN`

Environment `staging`:

- `AWS_ROLE_TO_ASSUME`
- `TERRAFORM_STATE_BUCKET`
- `TERRAFORM_LOCK_TABLE` (compatibility input)
- `JWT_SECRET_KEY`

Environment `production`:

- `AWS_ROLE_TO_ASSUME`
- `AWS_REGION`
- `TF_VERSION`
- `TERRAFORM_STATE_BUCKET`
- `TERRAFORM_LOCK_TABLE` (compatibility input)
- `JWT_SECRET_KEY`

Environment variables (`vars`):

- `APP_URL` in `staging`
- `APP_URL` in `production`

### AWS Secrets Manager (runtime)

Runtime app secrets (for backend task runtime) should be stored as environment-scoped secrets, for example:

- `/myproject/staging/db-password`
- `/myproject/staging/jwt-secret`
- `/myproject/prod/db-password`
- `/myproject/prod/jwt-secret`

### Local development

- Use `config/.env.dev` -> `deploy/.env`
- Keep local values local; `deploy/.env` must stay gitignored

## Terraform backend note

Terraform backend locking is now based on `use_lockfile=true`.

The workflows still expose `TERRAFORM_LOCK_TABLE` input for compatibility, but new setup should prioritize lockfile backend behavior.

## Rotation guidance

- Rotate critical secrets regularly
- Rotate immediately after accidental exposure
- Document rotation date, owner, and impacted systems

## Incident response (secret exposure)

1. Revoke or rotate the exposed secret immediately
2. Update dependent systems and deployments
3. Redeploy affected services
4. Audit logs and document incident timeline
