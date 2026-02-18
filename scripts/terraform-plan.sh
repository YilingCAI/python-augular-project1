#!/bin/bash

################################################################################
# terraform-plan.sh - Terraform Plan with IaC Scanning
# Generates infrastructure change plan and runs security scanning
# Usage: ENV=staging bash scripts/terraform-plan.sh
################################################################################

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

echo -e "${BLUE}🏗️  Terraform Plan for ${ENV}${NC}"

# ============================================================================
# Setup
# ============================================================================

TF_ROOT="${TF_ROOT:-./infra}"
TFVARS_FILE="${TF_ROOT}/envs/${ENV}.tfvars"
TFPLAN_FILE="/tmp/tfplan.${ENV}"

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
dynamodb_table = "${TERRAFORM_LOCK_TABLE}"
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
echo -e "${BLUE}║${NC} State Lock Table:        ${TERRAFORM_LOCK_TABLE}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Save plan artifact for CI/CD
mkdir -p "/tmp/tf-plans"
cp "${TFPLAN_FILE}" "/tmp/tf-plans/tfplan.${ENV}"

echo -e "${GREEN}✅ Terraform plan complete${NC}"
echo -e "${YELLOW}📝 Next step: make tf-apply ENV=${ENV}${NC}"
