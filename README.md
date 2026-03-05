# MyPythonProject1

Production-ready full-stack app with FastAPI + Angular + PostgreSQL on AWS ECS Fargate, provisioned by Terraform and delivered through GitHub Actions.

## High-level architecture

- Frontend: Angular app served by Nginx in ECS Fargate
- Backend: FastAPI service in ECS Fargate
- Database: PostgreSQL on AWS RDS
- Networking: ALB + VPC (public/private/db subnets)
- Runtime secrets: AWS Secrets Manager
- Infra state: S3 backend with native lockfile locking (`use_lockfile=true`)
- Images: Amazon ECR for both staging and production deploy flows

## Repository structure

```text
.
├── backend/          # FastAPI service + alembic + tests
├── frontend/         # Angular application
├── infra/            # Terraform root + modules + env tfvars
├── deploy/           # docker-compose local stack
├── config/           # env templates and ops guides
├── docs/             # architecture / onboarding / testing docs
└── .github/          # workflows and composite CI/CD actions
```

## Local development

### Prerequisites

- Docker Desktop
- Python 3.12+
- Poetry
- Node.js 20+
- Make

### Start full stack

```bash
make install
cp config/.env.dev deploy/.env
docker compose -f deploy/docker-compose.yml up --build
```

URLs:

- Frontend: http://localhost:4200
- Backend: http://localhost:8000
- API docs: http://localhost:8000/docs
- Health: http://localhost:8000/health

## Testing

```bash
make test
make backend-test
make frontend-test
```

Backend split:

```bash
cd backend
poetry run pytest tests/unit -m unit -v
poetry run pytest tests/integration -m integration -v
```

## CI/CD

Detailed reference: `.github/GITHUB_ACTIONS_CICD.md`

- `ci.yml`
  - Trigger: PR/push on `main` and `develop`
  - Runs lint/tests/security/dependency audit + Terraform fmt/validate/plan
  - Does not deploy
- `staging.yml`
  - Trigger: successful CI workflow on `develop` or manual dispatch
  - Builds/pushes backend+frontend images to ECR
  - Applies Terraform for staging
  - Forces ECS rollout and runs smoke test
- `release.yml`
  - Flow 1: successful CI on `main` runs semantic-release
  - Flow 2: `v*` tag builds/pushes ECR images, applies prod Terraform, deploys ECS, runs smoke test

## Environment configuration

Non-secret configuration files:

- `config/.env.dev` (local docker compose)
- `config/.env.test` (tests/CI)
- `config/.env.staging` (staging workflow runtime config)
- `config/.env.production` (reference values)

Operational docs:

- `config/environment-setup.md`
- `config/secrets-management.md`

## Manual infrastructure commands

From repository root:

```bash
make tf-validate ENV=staging
make tf-plan ENV=staging
make tf-apply ENV=staging
```

Destroy (destructive):

```bash
make tf-destroy ENV=staging
```

## AWS bootstrap

At minimum, create:

1. S3 bucket for Terraform state
2. GitHub OIDC provider in IAM
3. IAM roles assumed by GitHub Actions environments (`staging`, `production`)
4. ECR repositories for backend/frontend images

Run bootstrap:

```bash
make bootstrap
```

Optional inputs:

```bash
GITHUB_ORG=<org> GITHUB_REPO=<repo> AWS_REGION=us-east-1 make bootstrap
```

See `infra/README.md` for full bootstrap and IAM guidance.

## Versioning

- Commits follow Conventional Commits
- `release.yml` uses semantic-release to generate version tags and release notes
- Production deploys are triggered by semantic tags (`v*`)

## Common commands

```bash
make help
make lint
make format
make backend
make frontend
make dev
```
