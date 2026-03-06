# Repo Split Plan: `infra` and `app`

This guide splits the current monorepo into:

- **`mypythonproject1-infra`**: Terraform only
- **`mypythonproject1-app`**: Backend + Frontend app code and app deployment

## 1) Target boundaries

### `mypythonproject1-infra` should contain

- Terraform root files at repository root (`main.tf`, `variables.tf`, `providers.tf`, `outputs.tf`)
- `envs/` and `modules/`
- optional: `scripts/terraform-*.sh`
- optional: `bootstrap/`
- `.github/workflows/terraform-deploy.yml`
- reusable local actions currently used by Terraform workflows:
  - `.github/actions/aws-auth/`
  - `.github/actions/terraform/`

### `mypythonproject1-app` should contain

- `backend/`
- `frontend/`
- `deploy/` (only app runtime/developer compose assets)
- app workflows (`ci.yml`, app deploy workflow)
- reusable local actions for app workflow:
  - `.github/actions/aws-auth/`
  - `.github/actions/docker-build/`
  - `.github/actions/ecs/`
  - `.github/actions/publish-test-results/`

## 2) Shared contract between repos

Keep these values aligned between repos:

- AWS account/region
- ECR repos: `mypythonproject1/backend`, `mypythonproject1/frontend`
- ECS cluster + service names
- environment names: `dev`, `staging`, `prod`

Recommended: store these as GitHub **Environment Variables** with same names in both repos.

## 3) Deployment ownership

- **Infra repo workflow**: Terraform validate/plan/apply only.
- **App repo workflow**: Build/push Docker images and force ECS rolling deploy only.

This avoids circular ownership and keeps Terraform state lifecycle independent from app releases.

## 4) Rollout order

1. Create `mypythonproject1-infra` and move Terraform files.
2. Set Infra repo secrets/vars (`AWS_ROLE_TO_ASSUME`, state bucket, lock table, `JWT_SECRET_KEY`, region).
3. Run Terraform workflow once (staging first) and validate no infra drift.
4. Create `mypythonproject1-app` and move backend/frontend + app actions/workflows.
5. Set App repo secrets/vars (`AWS_ROLE_TO_ASSUME`, region, cluster/service names).
6. Run app CI, then app deploy workflow.

## 5) Cross-repo trigger options

Choose one:

- **Manual gate (recommended at first)**: run infra deploy, then app deploy manually.
- **Automated**: infra repo emits `repository_dispatch` to app repo after successful apply.

Start manual, then automate once stable.

## 6) Notes from your current setup

- Existing staging/release workflows currently do both Terraform and app deploy together.
- During split, remove Terraform jobs from app deploy workflow and keep only image build + ECS rollout.
- Keep Terraform PR plan in infra repo CI only.

## 7) Templates

- Infra workflow template: `docs/repo-split/templates/infra/.github/workflows/terraform-deploy.yml`
- App workflow template: `docs/repo-split/templates/app/.github/workflows/app-deploy.yml`
