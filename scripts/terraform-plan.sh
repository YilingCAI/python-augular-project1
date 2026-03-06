#!/usr/bin/env bash
###############################################################################
# terraform-plan.sh — Terraform plan with optional IaC security scan
#
# Initialises Terraform against the remote S3 backend, generates a binary
# plan for the requested environment, and optionally runs Checkov against
# the Terraform source for security best-practice violations.
#
# The compiled plan file is saved to /tmp/tf-plans/tfplan.<ENV> and is
# consumed automatically by terraform-apply.sh.
#
# Usage:
#   ENV=staging bash scripts/terraform-plan.sh
#   make tf-plan ENV=staging
#
# Environment variables:
#   ENV                     REQUIRED — target environment: dev | staging
#   TERRAFORM_STATE_BUCKET  REQUIRED — S3 bucket holding Terraform state
#   AWS_REGION              REQUIRED — AWS region
#   TF_ROOT                 optional — Terraform directory  (default: ../mypythonproject1-infra)
#
# Dependencies:   terraform; checkov (optional — skipped if not on PATH)
# Caller(s):      make tf-plan  /  called automatically by terraform-apply.sh
###############################################################################

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================================================
# Validation
# ============================================================================

if [ -z "${ENV:-}" ]; then
    echo -e "${RED}❌ ENV not set${NC}"
    exit 1
fi

if [[ "${ENV}" =~ ^(prod|production)$ ]]; then
    echo -e "${RED}❌ Local production runs are disabled.${NC}"
    echo -e "${YELLOW}Use GitHub Actions release workflow for production infrastructure changes.${NC}"
    exit 1
fi

echo -e "${BLUE}🏗️  Terraform Plan for ${ENV}${NC}"

# ============================================================================
# Setup
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_ROOT="${TF_ROOT:-${PROJECT_ROOT}/../mypythonproject1-infra}"
TFVARS_FILE="${TF_ROOT}/envs/${ENV}.tfvars"
TFPLAN_FILE="/tmp/tfplan.${ENV}"

if [ ! -f "$TFVARS_FILE" ]; then
    echo -e "${RED}❌ Variables file not found: $TFVARS_FILE${NC}"
    exit 1
fi

# Provide safe local defaults for dev-only planning when required vars are unset.
if [ "$ENV" = "dev" ]; then
    if [ -z "${TF_VAR_ecr_repository_url:-}" ]; then
        AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
        if [ -z "$AWS_ACCOUNT_ID" ]; then
            AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)
        fi
        if [ -n "$AWS_ACCOUNT_ID" ]; then
            export TF_VAR_ecr_repository_url="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/mypythonproject1/backend"
            echo -e "${YELLOW}⚠️  TF_VAR_ecr_repository_url not set; using dev default: ${TF_VAR_ecr_repository_url}${NC}"
        fi
    fi

    if [ -z "${TF_VAR_jwt_secret_key:-}" ]; then
        export TF_VAR_jwt_secret_key="dev-local-jwt-secret-change-me"
        echo -e "${YELLOW}⚠️  TF_VAR_jwt_secret_key not set; using dev-only placeholder value${NC}"
    fi
fi

if [ -z "${TF_VAR_ecr_repository_url:-}" ]; then
    echo -e "${RED}❌ Missing required TF_VAR_ecr_repository_url${NC}"
    echo -e "${YELLOW}Set it explicitly (for non-dev): export TF_VAR_ecr_repository_url=<account>.dkr.ecr.<region>.amazonaws.com/mypythonproject1/backend${NC}"
    exit 1
fi

if [ -z "${TF_VAR_jwt_secret_key:-}" ]; then
    echo -e "${RED}❌ Missing required TF_VAR_jwt_secret_key${NC}"
    echo -e "${YELLOW}Set it explicitly (for non-dev): export TF_VAR_jwt_secret_key=<strong-secret>${NC}"
    exit 1
fi

# ============================================================================
# Terraform Backend Configuration
# ============================================================================

echo -e "${BLUE}📝 Configuring Terraform backend...${NC}"

cat > "${TF_ROOT}/backend-config.hcl" << EOF
bucket         = "${TERRAFORM_STATE_BUCKET}"
key            = "terraform/${ENV}/terraform.tfstate"
region         = "${AWS_REGION}"
use_lockfile   = true
encrypt        = true
EOF

echo -e "${GREEN}✓${NC} Backend configured"

# ============================================================================
# Terraform Initialization
# ============================================================================

echo -e "${BLUE}📋 Initializing Terraform...${NC}"
terraform -chdir="${TF_ROOT}" init \
    -backend-config="backend-config.hcl" \
    -upgrade

echo -e "${GREEN}✓${NC} Terraform initialized"

# ============================================================================
# Terraform Plan
# ============================================================================

echo -e "${BLUE}📋 Running Terraform plan...${NC}"
terraform -chdir="${TF_ROOT}" plan \
    -var-file="envs/${ENV}.tfvars" \
    -out="${TFPLAN_FILE}" \
    -input=false

echo -e "${GREEN}✓${NC} Terraform plan generated: ${TFPLAN_FILE}"

# ============================================================================
# IaC Security Scanning (Checkov)
# ============================================================================

if command -v checkov &> /dev/null; then
    echo -e "${BLUE}🔒 Running Checkov IaC security scan...${NC}"
    checkov -d "${TF_ROOT}" \
        --framework terraform \
        --compact \
        --quiet || true
    echo -e "${GREEN}✓${NC} Checkov scan completed"
else
    echo -e "${YELLOW}⚠️  Checkov not installed, skipping security scan${NC}"
fi

# ============================================================================
# Plan Summary
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Terraform Plan Summary${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} Environment:             ${ENV}"
echo -e "${BLUE}║${NC} Variables File:          envs/${ENV}.tfvars"
echo -e "${BLUE}║${NC} Plan Output:             ${TFPLAN_FILE}"
echo -e "${BLUE}║${NC} State Backend:           ${TERRAFORM_STATE_BUCKET}/${ENV}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Save plan artifact for CI/CD
mkdir -p "/tmp/tf-plans"
cp "${TFPLAN_FILE}" "/tmp/tf-plans/tfplan.${ENV}"

echo -e "${GREEN}✅ Terraform plan complete${NC}"
echo -e "${YELLOW}📝 Next step: make tf-apply ENV=${ENV}${NC}"
