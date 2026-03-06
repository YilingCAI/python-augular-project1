#!/usr/bin/env bash
###############################################################################
# terraform-destroy.sh — Safely destroy Terraform-managed infrastructure
#
# ⚠️  THIS ACTION IS IRREVERSIBLE.  Use with extreme caution on production.
#
# Requires the operator to type "destroy <ENV>" at an interactive prompt
# before any resources are removed.  This prevents accidental teardown from
# typos, automation, or copy-paste errors.
#
# Steps:
#   1. Validates ENV is set and the matching .tfvars file exists
#   2. Prompts for explicit confirmation ("destroy <ENV>")
#   3. Writes a backend-config.hcl pointing at the correct S3 state
#   4. Runs terraform init  then  terraform destroy -auto-approve
#
# Usage:
#   ENV=staging bash scripts/terraform-destroy.sh
#   make tf-destroy ENV=staging
#
# Environment variables:
#   ENV                     REQUIRED — target environment: dev | staging
#   TERRAFORM_STATE_BUCKET  REQUIRED — S3 bucket holding Terraform state
#   AWS_REGION              REQUIRED — AWS region
#   TF_ROOT                 optional — Terraform directory  (default: ../mypythonproject1-infra)
#
# Dependencies:   terraform
# Caller(s):      make tf-destroy
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

# ============================================================================
# Confirmation
# ============================================================================

echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                    ⚠️  DANGER ZONE ⚠️${NC}"
echo -e "${RED}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${RED}║  This will DESTROY all infrastructure in: ${ENV}${NC}"
echo -e "${RED}║  This action CANNOT be undone!${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Type 'destroy ${ENV}' to confirm: " confirm
if [ "$confirm" != "destroy ${ENV}" ]; then
    echo -e "${YELLOW}❌ Destroy cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${RED}🗑️  Destroying infrastructure for ${ENV}${NC}"

# ============================================================================
# Setup
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_ROOT="${TF_ROOT:-${PROJECT_ROOT}/../mypythonproject1-infra}"
TFVARS_FILE="${TF_ROOT}/envs/${ENV}.tfvars"

if [ ! -f "$TFVARS_FILE" ]; then
    echo -e "${RED}❌ Variables file not found: $TFVARS_FILE${NC}"
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

# ============================================================================
# Terraform Initialization
# ============================================================================

echo -e "${BLUE}📋 Initializing Terraform...${NC}"
terraform -chdir="${TF_ROOT}" init \
    -backend-config="backend-config.hcl" \
    -upgrade

# ============================================================================
# Terraform Destroy
# ============================================================================

echo -e "${BLUE}🗑️  Running Terraform destroy...${NC}"
terraform -chdir="${TF_ROOT}" destroy \
    -var-file="envs/${ENV}.tfvars" \
    -auto-approve

echo -e "${GREEN}✓${NC} Terraform destroy completed"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            Terraform Destroy Summary${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} Environment:             ${ENV}"
echo -e "${BLUE}║${NC} State Backend:           ${TERRAFORM_STATE_BUCKET}/${ENV}"
echo -e "${BLUE}║${NC} Status:                  ✅ Destroyed"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✅ Terraform destroy complete${NC}"
