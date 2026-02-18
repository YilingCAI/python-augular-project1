# Makefile Quick Reference

All available Make targets with explanations.

## Overview

The Makefile provides a unified CLI for local development and CI/CD operations. All commands are environment-aware and support both local and production use.

## Development Targets

### `make help`
Displays all available targets with descriptions.
```bash
make help
```

### `make install`
Installs dependencies for backend and frontend.
```bash
make install
# Runs:
# - cd backend && pip install -e .
# - cd frontend && npm install
```

### `make dev`
Runs backend and frontend locally in parallel.
```bash
make dev
# Backend: http://localhost:8000
# Frontend: http://localhost:4200
# Database: localhost:5432
```

### `make backend`
Runs FastAPI backend only.
```bash
make backend
# Equivalent to: cd backend && uvicorn app.main:app --reload
```

### `make frontend`
Runs Angular frontend only.
```bash
make frontend
# Equivalent to: cd frontend && ng serve
```

## Testing Targets

### `make test`
Runs all tests (backend + frontend).
```bash
make test
# Backend: pytest
# Frontend: npm test
```

### `make backend-test`
Runs backend unit tests.
```bash
make backend-test
# Runs pytest with coverage
# Coverage report: htmlcov/index.html
```

### `make frontend-test`
Runs frontend unit tests.
```bash
make frontend-test
# Runs Jest with coverage
```

## Code Quality Targets

### `make lint`
Lints code for errors and style issues.
```bash
make lint
# Backend: ruff check .
# Frontend: ng lint
```

### `make format`
Formats code to match style standards.
```bash
make format
# Backend: black --line-length 100 .
# Frontend: ng format
```

## Terraform Targets

All Terraform targets require `ENV` parameter.

### `make tf-validate ENV=staging`
Validates Terraform syntax without state.
```bash
make tf-validate ENV=staging
# Validates: format, syntax, linting (tflint)
# Does NOT contact AWS or check state
```

### `make tf-plan ENV=staging`
Creates a plan of infrastructure changes.
```bash
make tf-plan ENV=staging
# Generates: /tmp/tf-plans/tfplan.staging
# Shows what will be created/changed/destroyed
# Runs Checkov for IaC security scanning
# ⚠️  Always review plan before apply!
```

### `make tf-apply ENV=staging`
Applies infrastructure changes.
```bash
make tf-apply ENV=staging
# ⚠️  Requires manual confirmation for prod
# Creates/updates/destroys AWS resources
# Exports outputs to: /tmp/tf-outputs-staging.json
```

### `make tf-destroy ENV=staging`
⚠️ **DANGEROUS** - Destroys all infrastructure.
```bash
make tf-destroy ENV=staging
# ⚠️  CONFIRMS TWICE before destroying
# Deletes all AWS resources in environment
# Use only for cleanup/teardown
```

## Docker Targets

All Docker targets require `ENV` and `IMAGE_TAG`.

### `make docker-build ENV=staging IMAGE_TAG=v1.0.0`
Builds Docker images for backend and frontend.
```bash
make docker-build ENV=staging IMAGE_TAG=v1.0.0
# Builds both images with provided tag
# Runs Trivy vulnerability scanning
# Does NOT push to registry yet
```

### `make docker-push ENV=staging IMAGE_TAG=v1.0.0`
Pushes Docker images to ECR.
```bash
make docker-push ENV=staging IMAGE_TAG=v1.0.0
# Authenticates with ECR
# Pushes both images
# Tags: latest, v1.0.0, sha-<commit>
```

## Deployment Targets

### `make ecs-deploy ENV=staging IMAGE_TAG=v1.0.0`
Deploys to ECS Fargate.
```bash
make ecs-deploy ENV=staging IMAGE_TAG=v1.0.0
# Updates ECS task definitions
# Updates ECS services with new images
# Waits for tasks to become healthy
# Verifies deployment success
```

### `make deploy ENV=staging IMAGE_TAG=v1.0.0`
Full deployment (terraform + docker + ECS).
```bash
make deploy ENV=staging IMAGE_TAG=v1.0.0
# 1. Docker build
# 2. Docker push
# 3. ECS deploy
# Complete application deployment in one command
```

### `make deploy-staging IMAGE_TAG=v1.0.0`
Shorthand for deploying to staging.
```bash
make deploy-staging IMAGE_TAG=v1.0.0
# Equivalent to: make deploy ENV=staging IMAGE_TAG=...
```

### `make deploy-prod IMAGE_TAG=v1.2.3`
Shorthand for deploying to production.
```bash
make deploy-prod IMAGE_TAG=v1.2.3
# ⚠️  Requires approval in GitHub Actions
# Equivalent to: make deploy ENV=prod IMAGE_TAG=...
```

## Cleanup Targets

### `make clean`
Removes build artifacts and caches.
```bash
make clean
# Removes: __pycache__, .pytest_cache, build/, dist/
# Clears: /tmp/tf-plans/, /tmp/tf-outputs-*.json
```

### `make clean-env`
Removes local environment files.
```bash
make clean-env
# Removes: .env.local, .env.staging, .env.prod
# ⚠️  Be careful! Removes all local config
```

## Parameter Reference

### `ENV` Parameter
Specifies the target environment.

**Valid values**: `dev`, `staging`, `prod`

```bash
make tf-plan ENV=staging      # Plan for staging
make tf-plan ENV=prod         # Plan for production
make tf-apply ENV=dev         # Apply to dev (if bootstrapped)
```

### `IMAGE_TAG` Parameter
Docker image tag for deployment.

**Formats**:
- Semantic versioning: `v1.0.0`
- Git SHA: `sha-abc123def456`
- Build number: `build-123`
- Any alphanumeric string

```bash
make docker-build ENV=staging IMAGE_TAG=v1.0.0
make docker-push ENV=staging IMAGE_TAG=v1.0.0
make ecs-deploy ENV=staging IMAGE_TAG=v1.0.0
```

## Usage Examples

### Local Development
```bash
# First time setup
make install

# Run locally
make dev

# Run tests
make test

# Format code
make format

# Lint code
make lint
```

### Before Committing
```bash
# Run full test suite
make test

# Format code
make format

# Lint code
make lint

# Then git commit
```

### Deploying to Staging
```bash
# Plan infrastructure changes
make tf-plan ENV=staging

# Review plan output, then apply
make tf-apply ENV=staging

# Build and push Docker images
make docker-build ENV=staging IMAGE_TAG=v1.0.0
make docker-push ENV=staging IMAGE_TAG=v1.0.0

# Deploy to ECS
make ecs-deploy ENV=staging IMAGE_TAG=v1.0.0

# Or all at once:
make deploy ENV=staging IMAGE_TAG=v1.0.0
```

### Deploying to Production
```bash
# Same as staging, but via GitHub Actions with approval
# Creates PR or merge to main → GitHub Actions triggers
# Manual approval required → deployment proceeds
# Monitor logs: aws logs tail /aws/ecs/myproject-prod --follow
```

### Debugging
```bash
# See what make will do (dry-run)
make -n tf-apply ENV=staging

# Set bash trace for scripts
set -x
make tf-plan ENV=staging
set +x

# Check Terraform state
cd infra && terraform show

# Check ECS status
aws ecs describe-services --cluster myproject-staging --services backend frontend
```

### Cleaning Up
```bash
# Remove build artifacts
make clean

# Remove local environment files
make clean-env

# Destroy infrastructure (DANGEROUS!)
make tf-destroy ENV=staging
```

## Error Handling

Most Make targets include error handling. If something fails:

1. **Read the error message carefully**
2. **Check prerequisites are installed** (Python, Node, Terraform, Docker, AWS CLI)
3. **Verify environment variables** (`ENV`, `IMAGE_TAG`)
4. **Check AWS credentials** (`aws sts get-caller-identity`)
5. **Look at logs** (`aws logs tail /aws/ecs/myproject-staging`)
6. **Run with debug** (`set -x && make target`)

## Tips & Tricks

### Parallel Execution
```bash
# Start multiple things in background
make backend &
make frontend &
wait

# Or in separate terminals
terminal 1: make backend
terminal 2: make frontend
```

### Dry Run
```bash
# See what will be executed without running it
make -n deploy ENV=staging IMAGE_TAG=v1.0.0
```

### Verbose Output
```bash
# See detailed logs
DEBUG=1 make tf-plan ENV=staging
```

### Skip Confirmation
```bash
# Some targets ask for confirmation, script them:
echo "y" | make tf-destroy ENV=staging
```

## Help & Documentation

```bash
# Show help
make help

# Show this reference
cat docs/MAKE_REFERENCE.md

# List all targets
make -p | grep '^[^.]'

# Show specific target
make -n tf-plan ENV=staging
```

## See Also

- [README.md](../README.md) - Main project overview
- [docs/DEPLOYMENT_GUIDE.md](../docs/DEPLOYMENT_GUIDE.md) - Detailed deployment procedures
- [docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) - Common issues
- Makefile - Source code for all targets
