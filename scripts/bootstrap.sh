#!/usr/bin/env bash
###############################################################################
# bootstrap.sh — Terraform-based AWS bootstrap
#
# Applies ../mypythonproject1-infra/bootstrap to provision one-time account prerequisites:
#   - S3 bucket for Terraform state
#   - DynamoDB lock table (optional, compatibility mode)
#   - ECR repositories (backend/frontend)
#   - GitHub OIDC provider
#   - GitHub Actions IAM role + inline policy
#
# Usage:
#   bash scripts/bootstrap.sh
#
# Optional environment variables:
#   AWS_REGION            default: us-east-1
#   PROJECT_NAME          default: mypythonproject1
#   GITHUB_ORG            default: inferred from git remote origin
#   GITHUB_REPO           default: inferred from git remote origin
#   GITHUB_ROLE_NAME      default: GitHubActionsRole
#   CREATE_LOCK_TABLE     default: true   (legacy compatibility)
#   STATE_BUCKET_NAME     default: terraform-state-<account-id>
###############################################################################

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_ROOT="${INFRA_ROOT:-${ROOT_DIR}/../mypythonproject1-infra}"
BOOTSTRAP_DIR="${INFRA_ROOT}/bootstrap"

if ! command -v terraform >/dev/null 2>&1; then
  echo "❌ terraform not found in PATH"
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "❌ aws CLI not found in PATH"
  exit 1
fi

AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-mypythonproject1}"
GITHUB_ROLE_NAME="${GITHUB_ROLE_NAME:-GitHubActionsRole}"
CREATE_LOCK_TABLE="${CREATE_LOCK_TABLE:-true}"
STATE_BUCKET_NAME="${STATE_BUCKET_NAME:-}"

infer_repo() {
  local remote
  remote="$(git -C "${ROOT_DIR}" config --get remote.origin.url 2>/dev/null || true)"
  if [[ -z "${remote}" ]]; then
    return 1
  fi

  remote="${remote%.git}"
  remote="${remote#git@github.com:}"
  remote="${remote#https://github.com/}"

  if [[ "${remote}" == *"/"* ]]; then
    echo "${remote}"
    return 0
  fi

  return 1
}

if [[ -z "${GITHUB_ORG:-}" || -z "${GITHUB_REPO:-}" ]]; then
  if inferred="$(infer_repo)"; then
    GITHUB_ORG="${GITHUB_ORG:-${inferred%/*}}"
    GITHUB_REPO="${GITHUB_REPO:-${inferred#*/}}"
  fi
fi

if [[ -z "${GITHUB_ORG:-}" || -z "${GITHUB_REPO:-}" ]]; then
  echo "❌ Unable to infer GITHUB_ORG/GITHUB_REPO. Set them explicitly and rerun."
  echo "   Example: GITHUB_ORG=my-org GITHUB_REPO=mypythonproject1 make bootstrap"
  exit 1
fi

echo "🚀 Running Terraform bootstrap"
echo "   Region: ${AWS_REGION}"
echo "   Project: ${PROJECT_NAME}"
echo "   Repo: ${GITHUB_ORG}/${GITHUB_REPO}"
echo "   Role: ${GITHUB_ROLE_NAME}"
echo "   Create lock table: ${CREATE_LOCK_TABLE}"

terraform -chdir="${BOOTSTRAP_DIR}" init -upgrade

tf_apply_args=(
  -auto-approve
  "-var=aws_region=${AWS_REGION}"
  "-var=project_name=${PROJECT_NAME}"
  "-var=github_org=${GITHUB_ORG}"
  "-var=github_repo=${GITHUB_REPO}"
  "-var=github_actions_role_name=${GITHUB_ROLE_NAME}"
  "-var=create_lock_table=${CREATE_LOCK_TABLE}"
)

if [[ -n "${STATE_BUCKET_NAME}" ]]; then
  tf_apply_args+=("-var=state_bucket_name=${STATE_BUCKET_NAME}")
fi

terraform -chdir="${BOOTSTRAP_DIR}" apply "${tf_apply_args[@]}"

AWS_ACCOUNT_ID="$(terraform -chdir="${BOOTSTRAP_DIR}" output -raw aws_account_id)"
TF_STATE_BUCKET="$(terraform -chdir="${BOOTSTRAP_DIR}" output -raw terraform_state_bucket)"
TF_LOCK_TABLE="$(terraform -chdir="${BOOTSTRAP_DIR}" output -raw terraform_lock_table)"
ROLE_ARN="$(terraform -chdir="${BOOTSTRAP_DIR}" output -raw github_actions_role_arn)"

echo
echo "✅ Bootstrap complete"
echo
echo "Set GitHub secrets:"
echo "  gh secret set AWS_ROLE_TO_ASSUME --body \"${ROLE_ARN}\""
echo "  gh secret set TERRAFORM_STATE_BUCKET --body \"${TF_STATE_BUCKET}\""
if [[ -n "${TF_LOCK_TABLE}" ]]; then
  echo "  gh secret set TERRAFORM_LOCK_TABLE --body \"${TF_LOCK_TABLE}\""
fi
echo
echo "Context:"
echo "  AWS account: ${AWS_ACCOUNT_ID}"
echo "  AWS region:  ${AWS_REGION}"
echo "  State bucket:${TF_STATE_BUCKET}"
if [[ -n "${TF_LOCK_TABLE}" ]]; then
  echo "  Lock table:  ${TF_LOCK_TABLE}"
else
  echo "  Lock table:  (disabled)"
fi
