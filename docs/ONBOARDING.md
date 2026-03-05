# Onboarding Guide

New developer path from clone to first successful PR.

## Prerequisites

- Git
- Docker Desktop
- Python 3.12+
- Poetry
- Node.js 20+
- Terraform 1.5+
- AWS CLI v2 (for infra/deploy work)

## Step 1 — Clone and install

```bash
git clone https://github.com/your-org/mypythonproject1.git
cd mypythonproject1
make install
```

## Step 2 — Configure local environment

```bash
cp config/.env.dev deploy/.env
```

This project keeps local non-secret defaults in `config/.env.dev`.

## Step 3 — Start local stack

```bash
docker compose -f deploy/docker-compose.yml up --build
```

Verify:

- Frontend: http://localhost:4200
- Backend docs: http://localhost:8000/docs
- Health: http://localhost:8000/health

## Step 4 — Run tests

```bash
make test
```

Backend test split:

```bash
cd backend
poetry run pytest tests/unit -m unit -v
poetry run pytest tests/integration -m integration -v
```

## Step 5 — Branch and commit rules

Branch strategy:

- `main`: production
- `develop`: integration branch
- `feature/*`: work branches from `develop`

Conventional commit format is required:

```text
feat(scope): add feature
fix(scope): fix behavior
docs: update docs
```

## Step 6 — Open PR to `develop`

CI (`ci.yml`) runs lint/tests/security/dependency checks and Terraform plan checks.

Primary required status: `quality-gate`.

## Step 7 — Deployment behavior after merge

- Merge to `develop` + successful CI -> `staging.yml` deploys to staging
- Merge to `main` + successful CI -> `release.yml` runs semantic-release
- Tag `v*` -> production deployment flow in `release.yml`

Both staging and production deployment flows build/push images to Amazon ECR.

## Common commands

```bash
make dev
make lint
make format
make backend
make frontend
make help
```

## Related docs

- `README.md`
- `docs/ARCHITECTURE.md`
- `docs/TEST_ARCHITECTURE.md`
- `infra/README.md`
- `.github/GITHUB_ACTIONS_CICD.md`
